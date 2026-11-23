"""M1 存档所需的中性可观察性补丁；两端保留相同原生规则。"""
from pathlib import Path


def apply(dest: Path, reference: bool, replace) -> None:
    enemy = dest / "src/doom/p_enemy.c"
    replace(enemy, 'void A_BrainSpit (mobj_t*\tmo)',
            '/* M1: persist the original low-skill spawn phase. */\n'
            'int m1_brain_easy = 0;\n\nvoid A_BrainSpit (mobj_t*\tmo)')
    replace(enemy, '    static int\teasy = 0;',
            '    /* M1: same state, accessible to the save supplement. */')
    replace(enemy, '    easy ^= 1;', '    m1_brain_easy ^= 1;')
    replace(enemy, '    if (gameskill <= sk_easy && (!easy))',
            '    if (gameskill <= sk_easy && (!m1_brain_easy))')
