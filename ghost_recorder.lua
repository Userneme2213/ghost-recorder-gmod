if SERVER then
    local isRecording = false
    local isPlaying = false
    local recordedData = {}
    local recordTarget = nil
    local ghostEntity = nil
    local playbackIndex = 1
    local ghostColor = Color(0, 255, 100, 200)

    concommand.Add("ghost_color", function(ply, cmd, args)
        local r = tonumber(args[1]) or 0
        local g = tonumber(args[2]) or 255
        local b = tonumber(args[3]) or 100
        ghostColor = Color(math.Clamp(r, 0, 255), math.Clamp(g, 0, 255), math.Clamp(b, 0, 255), 200)
        if IsValid(ply) then ply:ChatPrint("[Ghost] Цвет изменен.") end
    end)

    concommand.Add("ghost_record", function(ply, cmd, args)
        if isPlaying then
            ply:ChatPrint("[Ghost] Нельзя начинать запись во время воспроизведения!")
            return
        end

        if not isRecording then
            isRecording = true
            recordedData = {}
            recordTarget = ply
            ply:ChatPrint("[Ghost] Запись пошла... Двигайтесь!")
        else
            isRecording = false
            ply:ChatPrint("[Ghost] Запись остановлена. Записано кадров: " .. #recordedData)
        end
    end)

    concommand.Add("ghost_play", function(ply, cmd, args)
        if isRecording then
            ply:ChatPrint("[Ghost] Сначала остановите запись командой ghost_record!")
            return
        end

        if #recordedData == 0 then
            ply:ChatPrint("[Ghost] Нет данных для воспроизведения. Сначала запишите движение.")
            return
        end

        if isPlaying then
            isPlaying = false
            if IsValid(ghostEntity) then ghostEntity:Remove() end
            ply:ChatPrint("[Ghost] Воспроизведение прервано.")
            return
        end

        local firstFrame = recordedData[1]
        ghostEntity = ents.Create("prop_dynamic")
        if not IsValid(ghostEntity) then return end

        ghostEntity:SetModel(firstFrame.model)
        ghostEntity:SetPos(firstFrame.pos)
        ghostEntity:SetAngles(firstFrame.ang)
        ghostEntity:Spawn()

        ghostEntity:SetMaterial("models/wireframe")
        ghostEntity:SetRenderMode(RENDERMODE_TRANSALPHA)
        ghostEntity:SetColor(ghostColor)
        ghostEntity:SetCollisionGroup(COLLISION_GROUP_WORLD)

        playbackIndex = 1
        isPlaying = true
        ply:ChatPrint("[Ghost] Воспроизведение началось...")
    end)

    concommand.Add("ghost_clear", function(ply, cmd, args)
        recordedData = {}
        isRecording = false
        isPlaying = false
        if IsValid(ghostEntity) then ghostEntity:Remove() end
        ply:ChatPrint("[Ghost] Все записи удалены.")
    end)

    hook.Add("Tick", "GhostRecorderTick", function()
        if isRecording and IsValid(recordTarget) then
            table.insert(recordedData, {
                pos = recordTarget:GetPos(),
                ang = recordTarget:GetAngles(),
                model = recordTarget:GetModel(),
                sequence = recordTarget:GetSequence(),
                cycle = recordTarget:GetCycle()
            })
        end

        if isPlaying then
            if not IsValid(ghostEntity) then
                isPlaying = false
                return
            end

            local frame = recordedData[playbackIndex]
            if frame then
                ghostEntity:SetPos(frame.pos)
                ghostEntity:SetAngles(frame.ang)
                
                if ghostEntity:GetModel() ~= frame.model then
                    ghostEntity:SetModel(frame.model)
                    ghostEntity:SetMaterial("models/wireframe")
                end

                ghostEntity:SetSequence(frame.sequence)
                ghostEntity:SetCycle(frame.cycle)

                playbackIndex = playbackIndex + 1
            else
                isPlaying = false
                if IsValid(ghostEntity) then ghostEntity:Remove() end
                if IsValid(recordTarget) then
                    recordTarget:ChatPrint("[Ghost] Воспроизведение завершено.")
                end
            end
        end
    end)

    hook.Add("PlayerDisconnect", "GhostCleanUp", function(ply)
        if recordTarget == ply then
            isRecording = false
            isPlaying = false
            if IsValid(ghostEntity) then ghostEntity:Remove() end
            recordedData = {}
        end
    end)
end