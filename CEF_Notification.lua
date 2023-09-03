-- Автор этой библиотеки: MTG MODS (https://www.blast.hk/members/456827/)
-- Оптимизация и фикс говнокода: by Chapo (https://www.blast.hk/members/112329/)
-- Инструкция по использованию этой библиотеки: https://www.blast.hk/threads/187327/

return function(type, title, text, time)
    local str = ('window.executeEvent(\'event.notify.initialize\', \'["%s", "%s", "%s", "%s"]\');'):format(type, title, text, time)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 17)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt32(bs, #str)
    raknetBitStreamWriteString(bs, str)
    raknetEmulPacketReceiveBitStream(220, bs)
    raknetDeleteBitStream(bs)
end





