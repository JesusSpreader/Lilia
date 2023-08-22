--------------------------------------------------------------------------------------------------------
lia.config = lia.config or {}
lia.config.list = lia.config.list or {}
--------------------------------------------------------------------------------------------------------
function lia.config.load()
    lia.config.LoadCore()
    lia.config.LoadPermissions()
    lia.config.LoadModels()
    lia.config.LoadSchemaConfig()
    hook.Run("InitializedConfig")
end
--------------------------------------------------------------------------------------------------------