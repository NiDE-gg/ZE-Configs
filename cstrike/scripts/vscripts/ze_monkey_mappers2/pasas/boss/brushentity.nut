::archer_brush_model <- null

function OnPostSpawn() {
	if (self.GetName() == "pasas_archer_brushmdl")
		archer_brush_model = self.GetModelName()
	
	self.Kill()
}