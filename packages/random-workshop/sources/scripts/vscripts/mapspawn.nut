// This print statement is found in the original mapspawn.nut file
// There's no reason to keep it, other than to maintain normal console output
printl("==== calling mapspawn.nut");

// Ensure we're running on the server's script scope
if (!("Entities" in this)) return;

// The entrypoint function - called once entity I/O has initialized
::__elInit <- function () {
  if ("__elInitFlag" in this) return;
  ::__elFirstInit();
};

// Called only once on the initial map load
::__elFirstInit <- function () {
  ::__elInitFlag <- true;

  // Wait for the player to become available by recursing with a delay
  if (!GetPlayer()) {
    EntFireByHandle(Entities.First(), "RunScriptCode", "::__elFirstInit()", FrameTime(), null, null);
    return;
  }

  // The uppercase credits map is used as a way to return to a functioning menu
  if (GetMapName() == "SP_A5_CREDITS") {
    EntFire("credits", "Kill");
    EntFire("credits_music", "Kill");
    EntFire("logic_script", "Kill");
    EntFireByHandle(Entities.First(), "RunScriptCode", "SendToConsole(\"fadeout 0\")", FrameTime(), null, null);
    EntFireByHandle(Entities.First(), "RunScriptCode", "SendToConsole(\"disconnect\")", 1.0, null, null);
    return;
  }

  // Connect outputs to run finish events
  EntFire("@relay_pti_level_end", "AddOutput", "OnTrigger !self:RunScriptCode:__elFinish():0:1");
  EntFire("@changelevel", "AddOutput", "OnChangeLevel !self:RunScriptCode:__elFinish():0:1");
  ::RequestMapRating <- __elFinish;

  // Fix BEEmod maps with pellet dependency
  local pelletWarning = Entities.FindByName(null, "@stop_for_pellets");
  if (pelletWarning) pelletWarning.Destroy();

};

// Called when the map end condition is reached
::__elFinish <- function () {
  // Print this message as a signal to JS API that we need the next map
  printl("\n\nFetching a random map...");
  // Silently pause the game while the map is loaded
  SendToConsole("setpause nomsg");
};

// Run the entrypoint function as soon as entity I/O kicks in
EntFireByHandle(Entities.First(), "RunScriptCode", "::__elInit()", 0.0, null, null);
