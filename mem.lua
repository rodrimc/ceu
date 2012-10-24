_MEM = {
    off  = 0,
    max  = 0,
    gtes = {
        exts = {},
    },
}

function alloc (n)
    local cur = _MEM.off
    _MEM.off = _MEM.off + n
    _MEM.max = MAX(_MEM.max, _MEM.off)
    return cur
end

local t2n = {
     us = 10^0,
     ms = 10^3,
      s = 10^6,
    min = 60*10^6,
      h = 60*60*10^6,
}

F = {
    Root_pre = function (me)
        _MEM.gtes.wclock0 = alloc(_ENV.n_wclocks * _ENV.types.tceu_wclock)
        _MEM.gtes.async0  = alloc(_ENV.n_asyncs  * _ENV.types.tceu_lbl)
        _MEM.gtes.emit0   = alloc(_ENV.n_emits   * _ENV.types.tceu_lbl)
        for _, ext in ipairs(_ENV.exts) do
            _MEM.gtes[ext.n] = alloc(1 + (_ENV.awaits[ext] or 0)*_ENV.types.tceu_lbl)
        end
        _MEM.gtes.loc0 = alloc(0)
    end,

    Block_pre = function (me)
        me.off = _MEM.off

        for _, var in ipairs(me.vars) do
            local len
            if var.arr then
                len = _ENV.types[_TP.deref(var.tp)] * var.arr
            elseif _TP.deref(var.tp) then
                len = _ENV.types.pointer
            else
                len = _ENV.types[var.tp]
            end
            var.off = alloc(len)
            if var.isEvt then
                var.awt0 = alloc(1)
                alloc(_ENV.types.tceu_lbl*var.n_awaits)
            end

            local tp = _TP.no_(var.tp)
            if var.arr then
                var.val = '(('..tp..')(CEU->mem+'..var.off..'))'
            else
                var.val = '(*(('..tp..'*)(CEU->mem+'..var.off..')))'
            end
        end

        me.max = _MEM.off
    end,
    Block = function (me)
        for blk in _AST.iter'Block' do
            blk.max = MAX(blk.max, _MEM.off)
        end
        _MEM.off = me.off
    end,

    ParEver_aft = function (me, sub)
        me.lst = sub.max
    end,
    ParEver_bef = function (me, sub)
        _MEM.off = me.lst or _MEM.off
    end,
    ParOr_aft  = 'ParEver_aft',
    ParOr_bef  = 'ParEver_bef',
    ParAnd_aft = 'ParEver_aft',
    ParAnd_bef = 'ParEver_bef',

    ParAnd_pre = function (me)
        me.off = alloc(#me)        -- TODO: bitmap?
    end,
    ParAnd = 'Block',

    Var = function (me)
        me.val = me.var.val
    end,
    AwaitInt = function (me)
        local e = unpack(me)
        me.val = e.val
    end,
    EmitInt = function (me)
        local e1, e2 = unpack(me)
    end,

    --------------------------------------------------------------------------

    SetAwait = 'SetExp',
    SetExp = function (me)
        local e1, e2 = unpack(me)
    end,

    EmitExtS = function (me)
        local e1, _ = unpack(me)
        if e1.ext.output then
            F.EmitExtE(me)
        end
    end,
    EmitExtE = function (me)
        local e1, e2 = unpack(me)
        e1.acc = {e1.ext.id, 'cl', '_', false,
                    'event `'..e1.ext.id..'´ (line '..me.ln..')'}
        local len, val
        if e2 then
            local tp = _TP.deref(e1.ext.tp, true)
            if tp then
                len = 'sizeof('.._TP.no_(tp)..')'
                val = e2.val
            else
                len = 'sizeof('.._TP.no_(e1.ext.tp)..')'
                val = 'ceu_ext_f('..e2.val..')'
            end
        else
            len = 0
            val = 'NULL'
        end
        me.val = '\n'..[[
#if defined(ceu_out_event_]]..e1.ext.id..[[)
    ceu_out_event_]]..e1.ext.id..'('..val..[[)
#elif defined(ceu_out_event)
    ceu_out_event(OUT_]]..e1.ext.id..','..len..','..val..[[)
#else
    0
#endif
]]
    end,
    AwaitExt = function (me)
        local e1 = unpack(me)
        if _TP.deref(e1.ext.tp) then
            me.val = '(('.._TP.no_(e1.ext.tp)..')CEU->ext_data)'
        else
            me.val = '*((int*)CEU->ext_data)'
        end
    end,
    AwaitT = function (me)
        me.val = 'CEU->wclk_late'
    end,

    Op2_call = function (me)
        local _, f, exps = unpack(me)
        local ps = {}
        ASR((not _OPTS.c_calls) or _OPTS.c_calls[f.val],
            me, 'C calls are disabled')
        for i, exp in ipairs(exps) do
            ps[i] = exp.val
            local tp = _TP.deref(exp.tp, true)
        end
        me.val = f.val..'('..table.concat(ps,',')..')'
    end,

    Op2_idx = function (me)
        local _, arr, idx = unpack(me)
        me.val = '('..arr.val..'['..idx.val..'])'
    end,

    Op2_any = function (me)
        local op, e1, e2 = unpack(me)
        me.val = '('..e1.val..op..e2.val..')'
    end,
    ['Op2_-']  = 'Op2_any',
    ['Op2_+']  = 'Op2_any',
    ['Op2_%']  = 'Op2_any',
    ['Op2_*']  = 'Op2_any',
    ['Op2_/']  = 'Op2_any',
    ['Op2_|']  = 'Op2_any',
    ['Op2_&']  = 'Op2_any',
    ['Op2_<<'] = 'Op2_any',
    ['Op2_>>'] = 'Op2_any',
    ['Op2_^']  = 'Op2_any',
    ['Op2_=='] = 'Op2_any',
    ['Op2_!='] = 'Op2_any',
    ['Op2_>='] = 'Op2_any',
    ['Op2_<='] = 'Op2_any',
    ['Op2_>']  = 'Op2_any',
    ['Op2_<']  = 'Op2_any',
    ['Op2_||'] = 'Op2_any',
    ['Op2_&&'] = 'Op2_any',

    Op1_any = function (me)
        local op, e1 = unpack(me)
        me.val = '('..op..e1.val..')'
    end,
    ['Op1_~'] = 'Op1_any',
    ['Op1_-'] = 'Op1_any',
    ['Op1_!'] = 'Op1_any',

    ['Op1_*'] = function (me)
        local op, e1 = unpack(me)
        me.val = '('..op..e1.val..')'
    end,
    ['Op1_&'] = function (me)
        local op, e1 = unpack(me)
        me.val = '('..op..e1.val..')'
    end,

    ['Op2_.'] = function (me)
        local op, e1, id = unpack(me)
        me.val  = '('..e1.val..op..id..')'
    end,

    Op2_cast = function (me)
        local _, tp, exp = unpack(me)
        me.val = '(('.._TP.no_(tp)..')'..exp.val..')'
    end,

    WCLOCKK = function (me)
        local h,min,s,ms,us = unpack(me)
        me.us  = us*t2n.us + ms*t2n.ms + s*t2n.s + min*t2n.min + h*t2n.h
        me.val = me.us
        ASR(me.us>0 and me.us<=2000000000, me, 'constant is out of range')
    end,

    WCLOCKE = function (me)
        local exp, unit = unpack(me)
        me.us   = nil
        me.val  = exp.val .. '*' .. t2n[unit] .. 'L'
    end,

    WCLOCKR = function (me)
        me.val = 'PTR(CEU_WCLOCK0,tceu_wclock*)['..me.awt.gte..'].togo'
    end,

    C = function (me)
        me.val = string.sub(me[1], 2)
    end,
    SIZEOF = function (me)
        me.val = 'sizeof('.._TP.no_(me[1])..')'
    end,
    STRING = function (me)
        me.val = me[1]
    end,
    CONST = function (me)
        me.val = me[1]
    end,
    NULL = function (me)
        me.val = '((void *)0)'
    end,
}

_AST.visit(F)
