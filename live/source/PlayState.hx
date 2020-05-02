package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;

class PlayState extends FlxState
{
	public static inline var TILE_SIZE:Int = 32;

	public var player:FlxSprite;
	public var level:TiledLevel;
	public var coins:FlxGroup;
	public var shakeAmount:Float;

	override public function create()
	{
		super.create();
		this.bgColor = 0xffaaaaaa;

		this.level = new TiledLevel("assets/tiled/level.tmx");
		this.add(this.level.backgroundLayer);
		this.add(this.level.foregroundTiles);

		coins = new FlxGroup();
		for (p in this.level.coinsPosition)
		{
			var cc:FlxSprite = new FlxSprite(p.x, p.y);
			cc.loadGraphic("assets/tiled/coin.png");
			coins.add(cc);
		}
		this.add(coins);

		player = new FlxSprite(this.level.playerPosition.x, this.level.playerPosition.y);
		player.makeGraphic(TILE_SIZE, TILE_SIZE, FlxColor.RED);
		player.maxVelocity.x = 160;
		player.maxVelocity.y = 400;
		player.acceleration.y = 400;
		FlxG.camera.follow(player, FlxCameraFollowStyle.PLATFORMER);
		this.add(player);

		shakeAmount = 0.0;
	}

	private function handlePlayerLevelCollision()
	{
		for (l in this.level.collidableTileLayers)
		{
			FlxG.collide(l, player);
		}
	}

	public function playerCoinOverlap(p:FlxObject, c:FlxObject)
	{
		c.exists = false;
		c.visible = false;
		shakeAmount += 0.1;
	}

	override public function update(elapsed:Float)
	{
		player.velocity.x = 0;
		if (FlxG.keys.anyPressed(["LEFT", "A"]))
		{
			player.velocity.x = -player.maxVelocity.x;
		}
		else if (FlxG.keys.anyPressed(["RIGHT", "D"]))
		{
			player.velocity.x = player.maxVelocity.x;
		}
		if (FlxG.keys.anyPressed(["SPACE"]) && player.isTouching(FlxObject.FLOOR))
		{
			player.velocity.y = -player.maxVelocity.y / 2;
		}
		super.update(elapsed);

		// Collision
		handlePlayerLevelCollision();
		FlxG.overlap(player, coins, playerCoinOverlap);

		if (shakeAmount > 0.0)
		{
			FlxG.camera.shake(shakeAmount, 0.5);
			shakeAmount = 0.0;
		}
	}
}
