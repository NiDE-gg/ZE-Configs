// i dont know why this doesnt work normally

function spawn_particle(particle){
    DispatchParticleEffect(particle, self.GetOrigin(), self.GetAbsAngles().Forward())
}