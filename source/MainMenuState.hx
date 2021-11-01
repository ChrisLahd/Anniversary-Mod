package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxSort;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import WiggleEffect.WiggleEffectType;
import Song.SwagSong;

#if sys
import sys.FileSystem;
#end

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.4.2'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	private var generatedMusic:Bool = false;
	private var notes:FlxTypedGroup<Note>;
	public static var SONG:SwagSong;

	private var showCharacter:Character = null;
	private var showCharacter2:Character = null;
	private var showAwards:FlxSprite;
	private var showCredits:FlxSprite;
	private var showDonate:FlxSprite;
	private var showOptions:FlxSprite;
	

	
	var optionShit:Array<String> = ['story_mode', 'freeplay', #if ACHIEVEMENTS_ALLOWED 'awards', #end 'credits', #if !switch 'donate', #end 'options', 'q'];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var danceLeft:Bool = false;
	var bg:FlxSprite;


	override function create()
	{



		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		#if desktop
		FlxCamera.defaultCameras = [camGame];
		#end
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		FlxTween.linearMotion(bg, -80, -1280, -80, -80, 1, {ease: FlxEase.quadOut});

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);
		FlxTween.linearMotion(magenta, -80, -1280, -80, -80, 1, {ease: FlxEase.quadOut});

		
		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);
			
			
			
	
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 12);
			
			menuItem.animation.play('idle');
			
			menuItem.ID = i;
			menuItems.add(menuItem);
			
			
			var scr:Float = (optionShit.length - 4) * 0.135;
			
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			
			menuItem.updateHitbox();
			
			FlxTween.linearMotion(menuItem, 80, 1280, 80, -10 + (i * 110), 0.5, {ease: FlxEase.quadOut});

		}

		

		FlxG.camera.follow(camFollowPos, null, 1);

		showCharacter = new Character(800, -130, 'menubf', true);
		showCharacter.setGraphicSize(Std.int(showCharacter.width * 0.8));
		add(showCharacter);

		showCharacter.visible = false;

		showCharacter2 = new Character(500, -130, 'menu', true);
		showCharacter2.setGraphicSize(Std.int(showCharacter2.width * 0.8));
		add(showCharacter2);

		showCharacter2.visible = false;

		showAwards = new FlxSprite(600, 50).loadGraphic(Paths.image('menuicons/awards'));
		add(showAwards);

		showAwards.visible = false;
		
		showCredits = new FlxSprite(600, 250).loadGraphic(Paths.image('menuicons/credits'));
		add(showCredits);

		showCredits.visible = false;

		showDonate = new FlxSprite(600, 250).loadGraphic(Paths.image('menuicons/donate'));
		add(showDonate);

		showDonate.visible = false;

		showOptions = new FlxSprite(600, 450).loadGraphic(Paths.image('menuicons/options'));
		add(showOptions);

		showOptions.visible = false;



		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (!Achievements.achievementsUnlocked[achievementID][1] && leDate.getDay() == 5 && leDate.getHours() >= 18) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
			Achievements.achievementsUnlocked[achievementID][1] = true;
			giveAchievement();
			ClientPrefs.saveSettings();
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	var achievementID:Int = 0;
	function giveAchievement() {
		add(new AchievementObject(achievementID, camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement ' + achievementID);
	}
	#end

	var selectedSomethin:Bool = false;

	

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;


		//new FlxTimer().start(2.35, function(tmr:FlxTimer)
		//{
		//	FlxTween.tween(FlxG.camera, {zoom: 1.1}, 0.05, {ease: FlxEase.quadInOut});
     	//	new FlxTimer().start(0.03, function(tmr:FlxTimer)
		//	{
		//		FlxTween.tween(FlxG.camera, {zoom: 1}, 0.03, {ease: FlxEase.quadInOut});
		//	});
		//});

		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 5.6, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (optionShit[curSelected] == 'story_mode')
		{
	        changeItem(-1);
            changeItem(1); // This is to fix tween                           // BF IN MAIN MENU
            showCharacter.dance();
            showCharacter.updateHitbox();
            showCharacter.visible = true;
		}

		else 
		
		{
			showCharacter.visible = false;
		}
			
		if (optionShit[curSelected] == 'freeplay')
		{
			changeItem(-1);
            changeItem(1);
			showCharacter2.dance();
			showCharacter2.updateHitbox();
            showCharacter2.visible = true;	
		}
		
		else

		{
    		showCharacter2.visible = false;
		}
		
		if (optionShit[curSelected] == 'awards')
		{
			changeItem(-1);
			changeItem(1);
			showAwards.updateHitbox();
			showAwards.visible = true;	
		}
		
		else

    	{
			showAwards.visible = false;
		}


		if (optionShit[curSelected] == 'credits')
		{
			changeItem(-1);
			changeItem(1);
			showCredits.updateHitbox();
			showCredits.visible = true;	
		}
		
		else

		{
			showCredits.visible = false;
		}
		
		
		if (optionShit[curSelected] == 'credits')
		{
			changeItem(-1);
			changeItem(1);
			showCredits.updateHitbox();
			showCredits.visible = true;	
		}
		
		else

		{
			showCredits.visible = false;
		}



		if (optionShit[curSelected] == 'donate')
		{
			changeItem(-1);
			changeItem(1);
			showDonate.updateHitbox();
			showDonate.visible = true;	
		}
		
		else

		{
			showDonate.visible = false;
		}
		

		if (optionShit[curSelected] == 'options')
			{
				changeItem(-1);
				changeItem(1);
				showOptions.updateHitbox();
				showOptions.visible = true;	
			}
			
			else
	
			{
				showOptions.visible = false;
			}
		
		

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}

				if (optionShit[curSelected] == 'q')
				{
					selectedSomethin = true;
					
					FlxG.sound.music.stop();

					startVideo('gooblejumpscare');
					
					new FlxTimer().start(2.1, function(tmr:FlxTimer)
					{
						// Gives the gooble jumpscare time to jumpscare you, and makes it not spammable
						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);

					
				    	selectedSomethin = false;
					});
			}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					if(ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode':
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										MusicBeatState.switchState(new OptionsState());
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (FlxG.keys.justPressed.SEVEN)
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			else if(FlxG.keys.justPressed.SIX)
			{
				FlxG.save.data.skin = 1;
			}
			else if(FlxG.keys.justPressed.FIVE)
		    {
				FlxG.save.data.skin = 0;
			}

			#end
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.x = 130;
		});
	}

	public function startVideo(name:String):Void {
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXT); #else ''; #end
		#if sys
		if(FileSystem.exists(fileName)) {
			foundFile = true;
		}
		#end

		if(!foundFile) {
			fileName = Paths.video(name);
			#if sys
			if(FileSystem.exists(fileName)) {
			#else
			if(OpenFlAssets.exists(fileName)) {
			#end
				foundFile = true;
			}
		}
	

		if(foundFile) {
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			add(bg);
                bg.setGraphicSize(Std.int(bg.width * 1.1));

			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);
			
			}
			return;
		} else {
			FlxG.log.warn('Couldnt find video file: ' + fileName);
		}
		#end
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.offset.y = 0;
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
				spr.offset.x = 0.15 * (spr.frameWidth / 2 + 180);
				spr.offset.y = 0.15 * spr.frameHeight;
				FlxG.log.add(spr.frameWidth);
			}
		});
	}
	
}