if SERVER then
    local isRecording = false
    local isPlaying = false
    local recordedData = {}
    local recordTarget = nil
    local ghostEntity = nil
    local playbackIndex = 1

    
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

        -- Если уже играет, то выключаем
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

        
        ghostEntity:SetRenderMode(RENDERMODE_TRANSALPHA)
        ghostEntity:SetColor(Color(0, 150, 255, 120)) -
        ghostEntity:SetCollisionGroup(COLLISION_GROUP_WORLD) -

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
                -- 
                ghostEntity:SetPos(frame.pos)
                ghostEntity:SetAngles(frame.ang)
                
                if ghostEntity:GetModel() ~= frame.model then
                    ghostEntity:SetModel(frame.model)
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