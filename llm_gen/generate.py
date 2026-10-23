"""Model loading (4-bit, fits a T4) and raw generation."""
import gc

from config import MAX_NEW_TOKENS, MAX_NEW_TOKENS_FOR, TEMPERATURE
from prompts import build_prompt, code_prefix, family
from rtl_checks import design_end, finish_base_output, is_looping

def load_model(model_id):
    import torch
    from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig
    bnb = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_quant_type="nf4",
                             bnb_4bit_compute_dtype=torch.float16, bnb_4bit_use_double_quant=True)
    tok = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True)
    if tok.pad_token is None:
        tok.pad_token = tok.eos_token
    model = AutoModelForCausalLM.from_pretrained(model_id, quantization_config=bnb, device_map="auto",
                                                 trust_remote_code=True, low_cpu_mem_usage=True).eval()
    return tok, model

def free_model(*objs):
    import torch
    del objs; gc.collect(); torch.cuda.empty_cache()

def generate_raw(tok, model, model_id, task, lang):
    import torch
    from transformers import StoppingCriteria, StoppingCriteriaList
    prompt = build_prompt(tok, model_id, task, lang)
    inputs = tok([prompt], return_tensors="pt").to(model.device)
    start  = inputs["input_ids"].shape[1]
    kw = dict(max_new_tokens=MAX_NEW_TOKENS_FOR.get(model_id, MAX_NEW_TOKENS), pad_token_id=tok.pad_token_id, repetition_penalty=1.05,
              do_sample=TEMPERATURE > 0, **({"temperature": TEMPERATURE} if TEMPERATURE > 0 else {}))
    if model.generation_config.eos_token_id is None:
        kw["eos_token_id"] = tok.eos_token_id
    is_base = family(tok, model_id) == "base"
    dec = lambda ids: tok.decode(ids, skip_special_tokens=True, clean_up_tokenization_spaces=False)

    class Loop(StoppingCriteria):                 # abort repetition loops instead of burning all tokens
        def __call__(self, ids, scores, **_):
            return (ids.shape[1] - start) % 64 == 0 and is_looping(dec(ids[0][start:]))

    class Done(StoppingCriteria):                 # base models never stop alone: stop once every required unit is closed
        def __call__(self, ids, scores, **_):
            if (ids.shape[1] - start) % 16:       # decode every 16 tokens only
                return False
            return design_end(code_prefix(task, lang) + dec(ids[0][start:]), lang, task["modules"]) is not None

    kw["stopping_criteria"] = StoppingCriteriaList([Loop()] + ([Done()] if is_base else []))
    with torch.no_grad():
        out = model.generate(**inputs, **kw)
    text = dec(out[0][start:])
    return finish_base_output(task, lang, text) if is_base else text