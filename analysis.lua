_ANALYSIS = {
    needsPrio = true,
    needsChk  = true,
    n_tracks  = _AST.root.n_tracks,
}

if _OPTS.analysis_use then
-----------------------

local _F = dofile(_OPTS.analysis_file)

_ANALYSIS.needsPrio  = _PROPS.has_emits or _F.needsChk
_ANALYSIS.needsChk   = _F.needsChk
_ANALYSIS.n_tracks   = _F.n_tracks
_ANALYSIS.n_reachs   = 0
_ANALYSIS.n_unreachs = 0
_ANALYSIS.isForever  = not _F.isReach[_AST.root.lbl.n]
_ANALYSIS.nd_acc     = 0

local N_LABELS = #_LABELS.list

function isConc (l1, l2)
    return _F.isConc[l1.n*N_LABELS+l2.n]
end

-- "needsPrio": i/j are concurrent, and have different priorities
if not _ANALYSIS.needsPrio then
    for i=1, N_LABELS do
        local l1 = _LABELS.list[i]
        for j=i+1, N_LABELS do
            local l2 = _LABELS.list[j]
            if isConc(l1,l2) then
                if l1.prio ~= l2.prio then
                    _ANALYSIS.needsPrio = true
                    break
                end
            end
        end
        if _ANALYSIS.needsPrio then
            break
        end
    end
end

-- "n_reachs" / "n_unreachs"
for _,lbl in ipairs(_LABELS.list) do
    if lbl.to_reach==false and _F.isReach[lbl.n] then
        _ANALYSIS.n_reachs = _ANALYSIS.n_reachs + 1
        WRN(false, lbl.me, lbl.err..' : should not be reachable')
    end
    if lbl.to_reach==true and (not _F.isReach[lbl.n]) then
        _ANALYSIS.n_unreachs = _ANALYSIS.n_unreachs + 1
--DBG(lbl.id)
        WRN(false, lbl.me, lbl.err..' : should be reachable')
    end
end

local ND = {
    cl  = { cl=true, tr=true,  wr=true,  rd=true,  aw=true  },
    tr  = { cl=true, tr=true,  wr=true,  rd=true,  aw=true  },
    wr  = { cl=true, tr=true,  wr=true,  rd=true,  aw=false },
    rd  = { cl=true, tr=true,  wr=true,  rd=false, aw=false },
    aw  = { cl=true, tr=true,  wr=false, rd=false, aw=false },
    no  = {},   -- never ND ('ref')
}

-- "nd_acc": i/j are concurrent, and have incomp. acc
for i=1, N_LABELS do
    local l1 = _LABELS.list[i]
    for j=i+1, N_LABELS do
        local l2 = _LABELS.list[j]
        if l1.acc and l2.acc then
        if l1.par[l2] and isConc(l1,l2) then
            local id1, md1, tp1, any1, str1 = unpack(l1.acc)
            local id2, md2, tp2, any2, str2 = unpack(l2.acc)
--DBG('===')
--DBG(l1.acc, id1, md1, tp1, any1, str1)
--DBG(l2.acc, id2, md2, tp2, any2, str2)
            local nd  = (id1==id2) or (md1=='cl' and md2=='cl') or
                        (any1 and _TP.contains(tp1,tp2)) or
                        (any2 and _TP.contains(tp2,tp1))
            local det = _ENV.dets[id1] and _ENV.dets[id1][id2] or
                        _ENV.pures[id1] or _ENV.pures[id2]
--DBG(id1, id2, _id, _dt)
            if nd and (not det) and ND[md1][md2] then
                DBG('WRN : nondeterminism : '..str1..' vs '..str2)
                _ANALYSIS.nd_acc = _ANALYSIS.nd_acc + 1
            end
        end
        end
    end
end

-----------------------
end