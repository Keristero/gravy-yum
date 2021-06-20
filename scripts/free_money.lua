function handle_player_join(player_id)
    local player_cash = Net.get_player_money(player_id)
    if player_cash < 2000 then
        Net.set_player_money(player_id,2000)
    end
end