﻿function MODULE:InitializedModules()
    scripted_ents.GetStored("base_gmodentity").t.Think = nil
end

function MODULE:GrabEarAnimation()
    return nil
end

function MODULE:MouthMoveAnimation()
    return nil
end
