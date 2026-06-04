# dialogues.gd
# Paste the DIALOGUES const into GameManager.gd
# Format: "[SPEAKER] text" — speaker keys must match DialogueBox.gd SPEAKERS dict
# NARRATOR lines have no speaker tag
extends Node

const DIALOGUES: Dictionary = {

	# -------------------------------------------------------------------------
	# FLOOR 6 — Intro
	# -------------------------------------------------------------------------
	"floor6_intro": [
		"We were dismissed early by our professor, who stated that the lecture was finished.",
		"I barely heard it over the sound of my own heartbeat. I'd been sitting in Room 604 for the last two hours, half-listening to the lecture, half-watching the sky turn from orange to a deep, bruised purple.",
		"Now the room was empty. Just me, the hum of a flickering fluorescent light, and the strange feeling that I had forgotten something important.",
		"I packed my bag slowly. Laptop, charger, a half-empty water bottle. My body felt hollowed out — the exhaustion of sitting too long, thinking too hard. My legs were already aching just at the thought of the stairs.",
		"[MC] Just get home... One floor at a time.",
		"The elevator doors were closed when I reached them. I pressed the button. Nothing. Pressed it again. A thin mechanical groan came from somewhere inside the shaft — deep, reluctant. Then silence.",
		"The small panel beside the doors flickered, then: OUT OF ORDER.",
		"Interesting... I didn't know the elevators were this high-end.",
		"I stood there for a moment, contemplating my next actions. The hallway behind me was empty. Every classroom door was shut.",
		"As usual... I have to take the open stairs.",
	],

	# -------------------------------------------------------------------------
	# FLOOR 5 — Wirefixer intro
	# -------------------------------------------------------------------------
	"floor5_intro": [
		"The fifth-floor hallway was lit, at least. Faintly, but lit. The overhead panels buzzed with a sound like trapped insects.",
		"I was halfway toward the stairway leading to the 4th floor when I heard a voice calling.",
		"[ATE GIRL] Hey. Psstt. I'm over here.",
		"I stopped and turned around. She was standing there, arms crossed.",
		"[MC] What is it, ate?",
		"[ATE GIRL] Sit down for a minute. You look like you're about to collapse before you even hit the fourth floor.",
		"[MC] You're going down?",
		"[ATE GIRL] Trying to.",
		"She looked at me and raised an eyebrow.",
		"[ATE GIRL] Mm... The wire panel on the fifth floor east corridor, it's been sparking again. The one by the emergency exit. The door at the bottom of this floor's stairwell won't open unless the panel's fixed.",
		"[MC] .... Are you serious?",
		"She looked at me, deadpanned. She really was. AND SINCE WHEN WAS THERE A DOOR AT THE STAIRCASE??? She just nodded, and shrugged as if this was normal.",
		"I went straight to the east corridor to interact with the panel.",
	],

	# -------------------------------------------------------------------------
	# FLOOR 5 — Post wirefixer
	# -------------------------------------------------------------------------
	"floor5_post": [
		"Twenty minutes later, five wires, two ports, and a label stuck on upside down.",
		"When the green clicked home, the sparking stopped and the stairwell door exhaled open.",
		"I walked back and dropped onto the bench beside her to catch my breath.",
		"[MC] Thanks.",
		"But when I looked up again after a few seconds... she was gone.",
		"I headed through the unlocked door down to the next floor.",
	],

	# -------------------------------------------------------------------------
	# FLOOR 4 — Memory intro
	# -------------------------------------------------------------------------
	"floor4_intro": [
		"The fourth-floor hallway smelled like old coffee and erasable markers.",
		"I had a rhythm going — the kind of tired momentum that worked as long as you didn't stop — when a classroom door opened and a head appeared.",
		"[GUARD] You. Can you help me with something?",
		"The room was one of the computer labs. At the front, a projector displayed four colored panels in a sequence that pulsed and went dark.",
		"The guard standing by the teacher's desk — lanky, with unclear, eerie features — pointed at a locked cabinet in the corner.",
		"[GUARD] I need what's inside there. It's combination locked. The sequence is on the board.",
		"[MC] The board just shows colors.",
		"[GUARD] Yeah. In a sequence. Watch it long enough and it repeats.",
		"I approached the screen to analyze the pattern.",
	],

	# -------------------------------------------------------------------------
	# FLOOR 4 — Post memory
	# -------------------------------------------------------------------------
	"floor4_post": [
		"Blue. Yellow. Red. Blue. Green. Yellow.",
		"I pressed the buttons on the cabinet lock in order. On the third try, when the sequence was right, the lock clicked.",
		"[MC] How long have you been in here?",
		"I asked as I handed over the folder from inside the cabinet.",
		"The guard checked his watch, frowned, and then smiled.",
		"[GUARD] That's... a good question.",
		"He tapped my shoulder in appreciation.",
		"Before things could get any weirder, I left the room and hurriedly went down to the next floor.",
	],

	# -------------------------------------------------------------------------
	# FLOOR 3 — Lockpicker intro
	# -------------------------------------------------------------------------
	"floor3_intro": [
		"The third floor was darker. The overhead panels had given out entirely, leaving stretches of genuine shadow.",
		"In one of those patches, a door was deliberately jammed.",
		"Beside the handle was a lock panel — but it wasn't a standard number pad. It looked like a lock-picking alignment puzzle where you have to match shifting tumblers.",
	],

	# -------------------------------------------------------------------------
	# FLOOR 3 — Post lockpicker
	# -------------------------------------------------------------------------
	"floor3_post": [
		"The lock clicked open.",
		"Inside, instead of finding an item, I encountered the Janitor sitting quietly amidst the storage boxes. He looked at my exhaustion and nodded understandingly.",
		"[JANITOR] Tired, buddy? Don't worry, I'll go clear and unlock the elevator system for you downstairs so you don't have to keep walking.",
		"He left the room ahead of me to clear the elevator shaft mechanism.",
	],

	# -------------------------------------------------------------------------
	# FLOOR 2 — Jigsaw intro
	# -------------------------------------------------------------------------
	"floor2_intro": [
		"Outside the second-floor office, the Janitor pointed toward a dusty frame on the wall where a visual blueprint of the building's electrical core was broken into scattered pieces.",
		"[JANITOR] That's the elevator mechanism, friend.",
		"[JANITOR] It will only start running and open up once you complete the correct picture.",
	],

	# -------------------------------------------------------------------------
	# FLOOR 2 — Post jigsaw
	# -------------------------------------------------------------------------
	"floor2_post": [
		"The final piece clicked perfectly into place!",
		"Deep within the walls, a heavy metallic clunk echoed down the shaft. The elevator doors chimed beautifully and slid open.",
	],

	# -------------------------------------------------------------------------
	# FLOOR 1 — Find the Difference intro
	# -------------------------------------------------------------------------
	"floor1_intro": [
		"The elevator doors slid open into the eerie, silent ground floor lobby.",
		"The main gate was heavily chained shut, and standing right beside it was the guard, arms crossed, staring blankly.",
		"Before I could even step forward, the environment around me warped slightly.",
		"Two large, glowing frames manifested on the lobby walls, showing nearly identical photographs of the very room I was standing in.",
	],

	# -------------------------------------------------------------------------
	# FLOOR 1 — Post FtD, DEFAULT path
	# -------------------------------------------------------------------------
	"floor1_default_post": [
		"The images faded away.",
		"The guard slowly turned his head toward me.",
		"Your body and mind are completely drained.",
		"You watch the elevator doors begin to slide closed on their own, and a wave of pure dread hits you.",
		"Your instincts scream at you to get away from the elevator entirely.",
		"Your only choice is to face the exit gate.",
	],

	# -------------------------------------------------------------------------
	# FLOOR 1 — Post FtD, SECRET path
	# -------------------------------------------------------------------------
	"floor1_secret_post": [
		"The images faded away.",
		"The massive surge of adrenaline hits you all at once — your heart is pounding out of your chest.",
		"The guard steps forward, pointing a pale finger back toward the open elevator.",
		"[GUARD] Someone is waiting for you.",
		"His voice echoes unnaturally through the lobby.",
		"The surge lets you choose: force your way out through the side emergency door... or run back into the elevator.",
	],

	# -------------------------------------------------------------------------
	# ENDING — Default intro (before Run Away minigame)
	# -------------------------------------------------------------------------
	"ending_default_intro": [
		"You turn your back and sprint away from the elevator.",
		"Suddenly, the guard's face distorts into a pitch-black grin.",
		"The ambient lights flicker out completely as terrifying, oncoming shadows begin creeping from the edge of the lobby walls.",
		"I bolted toward the side emergency door.",
	],

	# -------------------------------------------------------------------------
	# ENDING — Default outro (after Run Away minigame)
	# -------------------------------------------------------------------------
	"ending_default_outro": [
		"I hammered against the final latch in perfect rhythm, forcing the side door to burst open!",
		"I collapsed outside into the cold, ordinary night air, running down the street without looking back.",
		"Behind me, the CSB building remained completely dead and dark.",
		"I escaped... but the unsettling feeling stayed with me.",
		"- The End (?) -",
	],

	# -------------------------------------------------------------------------
	# ENDING — Secret intro (before Snake minigame)
	# -------------------------------------------------------------------------
	"ending_secret_intro": [
		"I turned my back on the gate, stepped back into the elevator, and allowed the doors to close.",
		"With the adrenaline surge holding my heart together, I hit the hidden button panel.",
		"The elevator climbed past the 6th floor, straight into the undocumented 7th Floor.",
		"The doors opened onto a hallway that smelled like dried marker and something older.",
		"At the end of it, in a room with no nameplate, a cloaked figure sat at a teacher's desk. He had visible glasses and a distinct, watchful stillness.",
		"A laptop sat open in front of him, displaying a moving grid of green squares — a snake game.",
		"[SIR RYAN] Sit down. You found your way up.",
		"I didn't sit down.",
		"[MC] Sir Ryannn. You know what this is?",
		"[SIR RYAN] I'm going to need you to do better than me. I've been playing this for a long time. Longer than you'd believe.",
		"[MC] What happens if I win?",
		"[SIR RYAN] You wake up.",
	],

	# -------------------------------------------------------------------------
	# ENDING — Secret outro (after Snake minigame)
	# -------------------------------------------------------------------------
	"ending_secret_outro": [
		"The snake cleanly occupied the final empty square of the grid.",
		"[SIR RYAN] IMPOSSIBLE!!!",
		"The cloak was discarded. A shrill yell echoed in the room as Sir Ryan stomped toward me in absolute disbelief.",
		"Then, everything flashed into a pure, blinding white.",
		"I open my eyes.",
		"I am standing right in the middle of the real CSB lobby. It's daytime, bright, and loud with the chaotic chatter of students moving between periods.",
		"A phone plays music nearby, second-years are arguing over a project, and the reception desk is fully staffed. The elevator dings normally, letting out a crowd of regular people.",
		"My bag is on my shoulder. My water bottle is in my hand.",
		"I laugh softly to myself — a short sound that no one around me finds strange.",
		"I run a hand through my hair, look once more at the ordinary fluorescent lighting, and choose to take the stairs instead of the elevator.",
		"I have class on the sixth floor. And somewhere way above me, I am almost certain a ceiling tile is swaying gently, even though there isn't any breeze.",
		"As usual.",
		"- The End (TRUE ENDING) -",
	],
}
