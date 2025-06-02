// This file is shared with ze_dreamin_v2_1 and ze_dreamin_v3_1_css

function Display(amount)
{
    local x = amount;

    // Countdown loop
    for (local i = 0; i <= amount; i++)
    {
        if (x <= 0)
            break;

        // Update text based on remaining time
        local text = (x == 1) ? "      second left" : "      seconds left";
        EntFire("seconds_left", "AddOutput", "message " + text, i);
        EntFire("text_sec", "AddOutput", "message " + x.tostring(), i);

        // Display both texts
        EntFire("text_sec", "Display", "", i);
        EntFire("seconds_left", "Display", "", i);

        x--;
    }
}