title_name <- "title_overlay_c1_l1"

::FadeTitle <- function(title=1,endtime=2){

    switch (title) {
        case 1:
            title_name = "title_overlay_c1_l1"
            break;
        case 2:
            title_name = "title_overlay_c1_l2"
            break;
        case 3:
            title_name = "title_overlay_c1_l3"
            break;
        case 4:
            title_name = "title_overlay_c2_l1"
            break;
        case 5:
            title_name = "title_overlay_c2_l2"
            break;
        case 6:
            title_name = "title_overlay_c2_l3"
            break;
        case 7:
            title_name = "title_overlay_c3_l1"
            break;
        case 8:
            title_name = "title_overlay_c3_l2"
            break;
        case 9:
            title_name = "title_overlay_c3_l3"
            break;
        case 10:
            title_name = "title_overlay_c4_l1"
            break;
    }

    self.AcceptInput("CallScriptFunction", "StageOverlay_FadeIn", null, null)
    EntFireByHandle(self, "CallScriptFunction", "StageOverlay_FadeOut", endtime, null, null)
}

::StageOverlay_FadeIn <- function(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
        EntFire("client","Command","r_screenoverlay effects/shaders/mog/"+title_name,0,h);
	}
    SO_In()
}

::StageOverlay_FadeOut <- function(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
        EntFire("client","Command","r_screenoverlay effects/shaders/mog/"+title_name,0,h);
	}
    SO_Out()
}

::StageOverlay_Clear <- function(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
        EntFire("client","Command","r_screenoverlay null",0,h);
	}
    printl("screen cleared")
}

::WorldspawnDims <- function (valor1) {
    local world = Entities.FindByClassname(null, "worldspawn")
    printl(valor1)
    NetProps.SetPropVector(world, "m_WorldMins", Vector(valor1, 0, 0))
}

::SO_In <- function(){
    local ii = 0.00
    local alpha = 0.00

    for (local i=0; i < 100; i++) {
        EntFireByHandle(self, "RunScriptCode", "WorldspawnDims(" + alpha + ")", ii, null, null)
        ii+=0.01
        alpha+=0.01
    }
}

::SO_Out <- function(){
    local ii = 0.000
    local alpha = 1.00

    for (local i=0; i < 100; i++) {
        EntFireByHandle(self, "RunScriptCode", "WorldspawnDims(" + alpha + ")", ii, null, null)
        ii+=0.01
        alpha-=0.01
        if(i==99){
            EntFireByHandle(self, "CallScriptFunction", "StageOverlay_Clear", ii, null, null)
        }
    }
}