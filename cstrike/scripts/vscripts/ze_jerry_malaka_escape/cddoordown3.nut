function CDdoordown(amount)
{
    local x = amount;

    // Countdown loop
    for (local i = 0; i <= amount; i++)
    {
        if (x <= 0)
            break;

        // Update text based on remaining time
        local text = x.tostring() + ((x == 1) ? " second" : " seconds");
        EntFire("down_text", "AddOutput", "message " + text, i);
        EntFire("down_text", "Display", "", i);
        x--;
    }
}