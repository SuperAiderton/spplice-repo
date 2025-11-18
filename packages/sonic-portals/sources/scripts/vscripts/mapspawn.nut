if (!("Entities" in this)) return;
IncludeScript("ppmod");
IncludeScript("sl_sonic-portals");

printl("\n=== Loading Sonic Portals mod...");

::mod <- {};

mod.tracked_portals <- {};

mod.speedmod_float <- 1.0;

mod.portalcount_int <- 0;

mod.inFunnel_bool <- false;

mod.inCatapult_bool <- false;

mod.movement <- {
	moveleft = false,
	moveright = false,
	forward = false,
	back = false,
};

mod.setSpeed_fun <- function(value = 1) {
	mod.speedmod_float = value;
}

mod.increaseSpeedLevel_fun <- function() {
	mod.portalcount_int += 1;
	mod.speedmod_float = (1.0 / 3) * (54.0 - (50 / mod.portalcount_int));
}

mod.applyMovement <- function(pplayer) {
	// Calculate movement
	local TOTALMOVEMENT_FLOAT = 175.0;
	local movement = Vector(0, 0);
	if (mod.movement.moveright) {
		movement.x += TOTALMOVEMENT_FLOAT / 2;
		if (!(mod.movement.forward || mod.movement.back)) {
			movement.x += TOTALMOVEMENT_FLOAT / 2;
		}
	}
	if (mod.movement.moveleft) {
		movement.x -= TOTALMOVEMENT_FLOAT / 2;
		if (!(mod.movement.forward || mod.movement.back)) {
			movement.x -= TOTALMOVEMENT_FLOAT / 2;
		}
	}
	if (mod.movement.forward) {
		movement.y += TOTALMOVEMENT_FLOAT / 2;
		if (!(mod.movement.moveleft || mod.movement.moveright)) {
			movement.y += TOTALMOVEMENT_FLOAT / 2;
		}
	}
	if (mod.movement.back) {
		movement.y -= TOTALMOVEMENT_FLOAT / 2;
		if (!(mod.movement.moveleft || mod.movement.moveright)) {
			movement.y -= TOTALMOVEMENT_FLOAT / 2;
		}
	}
	movement.x *= mod.speedmod_float;
	movement.y *= mod.speedmod_float;
	
	// Fix upward funnels.
	mod.inFunnel_bool = false;
	ppmod.forent(["projected_tractor_beam_entity"], function(beam) {
		if (mod.inFunnel_bool) return; // no point in checking any more funnels

		local start = beam.GetOrigin() - beam.GetForwardVector() * 100;
		local end = start + beam.GetForwardVector() * 3000;

		local ray = ppmod.ray(start, end, GetPlayer(), false, null);
		// mod.inFunnel_bool == false case is avoided above
		mod.inFunnel_bool = ray.entity != null;
	});

	// Apply movement
	if (!mod.inFunnel_bool && !mod.inCatapult_bool) {
		pplayer.movesim(movement, 10.0, 0.0, 0.25, Vector(0,0,0));
	}
	
};

mod.start <- async (function() {
	local pplayer = ppmod.player(GetPlayer());
	yield pplayer.init().then(function(pplayer) {
		foreach(key, val in mod.movement) {
			pplayer.oninput("+" + key, "mod.movement." + key + " = true");
			pplayer.oninput("-" + key, "mod.movement." + key + " = false");
		}

		// Portal shot tracking
		ppmod.interval(function() {
			// find all new portals, except the first 2 placed
			local ent = null;
			while (ent = Entities.FindByClassname(ent, "prop_portal")) {
				ent.ValidateScriptScope();
				if (ent.GetScriptScope() in mod.tracked_portals) continue;
				mod.tracked_portals[ent.GetScriptScope()] <- 1;
				// attach function on place
				ppmod.addscript(ent, "OnPlacedSuccessfully", mod.increaseSpeedLevel_fun);
			}
		});

		// UI
		mod.speedmodText_ent <- ppmod.text("Speed: loading...", 0.005, 0.995);
		mod.speedmodText_ent.SetSize(0);
		ppmod.interval(function() {
			mod.speedmodText_ent.SetText("Speed: " + mod.speedmod_float);
			mod.speedmodText_ent.Display();
		});

	});
	ppmod.interval(function(): (pplayer) {
		mod.applyMovement(pplayer);
	});

	// Fix catapult movement suppression
	// Still doesn't implement non-default AirCtrlSupressionTime
	local trigger = null;
	while (trigger = ppmod.get("trigger_catapult", trigger)) {
		ppmod.addscript(trigger, "OnCatapulted", function () {
			mod.inCatapult_bool = true;
			// no race conditions since triggers aren't entered in rapid succession
			ppmod.ontick(function () {
				mod.inCatapult_bool = false;
			}, true, 8); // = 30 * 0.25 (quarter seconds)
		});
	}
})

ppmod.onauto(mod.start);