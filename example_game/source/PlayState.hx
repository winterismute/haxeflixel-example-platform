package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxTrailEffect;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;

class PlayState extends FlxState
{
	private static inline var TILE_SIZE:Int = 32;
	// These do not reset with state
	public static var currentScore:Int = 0;
	public static var maxTime:Float = 20.0;

	public var level:TiledLevel;

	public var player:FlxSprite;
	public var playerEffect:FlxEffectSprite;

	public var coins:FlxGroup;
	public var specialCoin:FlxSprite;

	// public var coins:FlxTypedSpriteGroup<FlxSprite>;
	private var scoreText:FlxText;
	private var timeText:FlxText;
	private var goal:FlxSprite;

	public var trailSprite:FlxEffectSprite;

	private var trailEffect:FlxTrailEffect;
	private var trailEffectTimer:FlxTimer;

	public var invertFilter:BitmapFilter;
	public var filters:Array<BitmapFilter>;

	public var shakeAmount:Float;
	public var timeLeft:Float;
	public var isGameOver:Bool;

	override public function create():Void
	{
		super.create();

		bgColor = 0xffaaaaaa;

		level = new TiledLevel("assets/tiled/level.tmx");
		this.add(level.backgroundLayer);
		this.add(level.foregroundTiles);

		goal = new FlxSprite(level.exitPosition.x, level.exitPosition.y);
		goal.makeGraphic(TILE_SIZE, TILE_SIZE, FlxColor.WHITE);
		this.add(goal);

		coins = new FlxGroup();
		// coins = new FlxTypedSpriteGroup<FlxSprite>();
		for (p in level.coinsPosition)
		{
			var c:FlxSprite = new FlxSprite(p.x, p.y);
			c.loadGraphic("assets/tiled/coin.png");
			coins.add(c);
		}
		this.add(coins);

		player = new FlxSprite(level.playerPosition.x, level.playerPosition.y).makeGraphic(TILE_SIZE, TILE_SIZE, FlxColor.RED);

		do
		{
			var randomPX:Float = FlxG.random.float(player.x, goal.x);
			var randomPY:Float = FlxG.random.float(player.y - 64, player.y + 32);
			specialCoin = new FlxSprite(randomPX, randomPY);
			specialCoin.loadGraphic("assets/tiled/coin.png");
		}
		while (FlxG.overlap(specialCoin, player) || FlxG.overlap(specialCoin, goal));
			// while (FlxG.overlap(specialCoin, player) || FlxG.overlap(specialCoin, goal) || spriteOverlapsLevel(specialCoin));
		specialCoin.color = FlxColor.RED;
		this.add(specialCoin);

		playerEffect = new FlxEffectSprite(player);
		player.maxVelocity.y = 400;
		player.acceleration.y = 400;
		player.maxVelocity.x = 160;
		// player.drag.x = player.maxVelocity.x * 4;
		FlxG.camera.follow(player);

		trailEffect = new FlxTrailEffect(playerEffect, 6, 0.5, 8);
		playerEffect.effects.push(trailEffect);
		trailEffect.active = false;
		this.add(playerEffect);
		playerEffect.visible = false;
		this.add(player);

		scoreText = new FlxText(10, 10, 100, "SCORE: " + currentScore, 12);
		scoreText.scrollFactor.set(0, 0);
		this.add(scoreText);

		timeLeft = maxTime;
		timeText = new FlxText(10, 10, 200, "TIME LEFT: " + FlxMath.roundDecimal(timeLeft, 2), 14);
		timeText.screenCenter();
		timeText.y = 10;
		timeText.scrollFactor.set(0, 0);
		this.add(timeText);

		var matrix:Array<Float> = [
			-1,  0,  0, 0, 255,
			 0, -1,  0, 0, 255,
			 0,  0, -1, 0, 255,
			 0,  0,  0, 1,   0,
		];
		invertFilter = new ColorMatrixFilter(matrix);
		filters = new Array<BitmapFilter>();
		FlxG.camera.setFilters(filters);

		this.trailEffectTimer = new FlxTimer();

		goal.visible = false;
		goal.exists = false;
		isGameOver = false;

		shakeAmount = 0.0;

		// FlxG.watch.add(this.player, "x");
	}

	public function setGameOver()
	{
		isGameOver = true;
		timeText.text = "GAME OVER!";
		this.remove(player); // stop updating and showing player
	}

	private function handlePlayerLevelCollision():Void
	{
		for (l in level.collidableTileLayers)
		{
			FlxG.collide(l, player);
		}
	}

	private function spriteOverlapsLevel(s:FlxSprite):Bool
	{
		for (l in level.collidableTileLayers)
		{
			if (FlxG.overlap(l, s))
			{
				return true;
			}
		}
		return false;
	}

	private function endOfTrail(timer:FlxTimer = null):Void
	{
		trailEffect.active = false;
		playerEffect.visible = false;
		player.visible = true;
		player.maxVelocity.y = 400;
		player.maxVelocity.x = 160;
	}

	private function onPlayerFloorOverlap(pl:FlxObject, f:FlxObject):Void
	{
		endOfTrail();
		setGameOver();
	}

	private function onPlayerGoalOverlap(pl:FlxObject, g:FlxObject):Void
	{
		endOfTrail();
		maxTime -= 1.0;
		FlxG.resetState();
	}

	private function onPlayerSpecialCoinOverlap(pl:FlxObject, sc:FlxObject):Void
	{
		sc.visible = false;
		sc.exists = false;
		shakeAmount += 0.10;
		currentScore += 300;
		scoreText.text = "SCORE: " + currentScore;

		// Turn on trail
		playerEffect.setPosition(player.x, player.y);
		trailEffect.active = true;
		playerEffect.visible = true;
		player.visible = false;
		player.maxVelocity.y = 500;
		player.maxVelocity.x = 240;
		this.trailEffectTimer.start(4, endOfTrail);
	}

	private function onPlayerCoinOverlap(pl:FlxObject, c:FlxObject):Void
	{
		c.visible = false;
		c.exists = false;
		shakeAmount += 0.005;
		currentScore += 100;
		scoreText.text = "SCORE: " + currentScore;

		if (filters.length > 0)
		{
			filters.remove(invertFilter);
			goal.visible = false;
			goal.exists = false;
		}
		else
		{
			filters.push(invertFilter);
			goal.visible = true;
			goal.exists = true;
		}
	}

	override public function update(elapsed:Float):Void
	{
		player.velocity.x = 0;
		if (timeLeft <= 0.0)
		{
			setGameOver();
		}
		else
		{
			timeLeft -= elapsed;
			timeText.text = "TIME LEFT: " + FlxMath.roundDecimal(timeLeft, 2);
		}

		if (!isGameOver)
		{
			if (FlxG.keys.anyPressed(["LEFT", "A"]))
			{
				player.velocity.x = -player.maxVelocity.x;
			}
			else if (FlxG.keys.anyPressed(["RIGHT", "D"]))
			{
				player.velocity.x = player.maxVelocity.x;
			}
			if (FlxG.keys.anyPressed([W, SPACE]) && player.isTouching(FlxObject.FLOOR))
			{
				player.velocity.y = -(player.maxVelocity.y / 2);
			}
		}

		if (playerEffect.visible)
		{
			playerEffect.setPosition(player.x, player.y);
		}
		super.update(elapsed);

		// Collisions
		if (!isGameOver)
		{
			handlePlayerLevelCollision();
			FlxG.overlap(player, specialCoin, onPlayerSpecialCoinOverlap);
			FlxG.overlap(player, coins, onPlayerCoinOverlap);
			FlxG.overlap(player, goal, onPlayerGoalOverlap);
			FlxG.overlap(player, level.floor, onPlayerFloorOverlap);
		}

		if (shakeAmount > 0.0)
		{
			FlxG.camera.shake(shakeAmount, 0.25);
			shakeAmount = 0.0;
		}
	}
}
