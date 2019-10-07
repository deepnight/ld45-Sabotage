package en;

class Bullet extends Entity {
	var source : Entity;
	public function new(e:Entity, ang:Float, ?spd=1.0) {
		super(0,0);

		source = e;
		hei = 0;
		frict = 1;
		hasCollisions = false;

		setPosPixel(e.footX+Math.cos(ang)*5, e.footY-4+Math.sin(ang)*5);

		spd*=0.2;
		dx = Math.cos(ang)*spd;
		dy = Math.sin(ang)*spd;

		spr.anim.playAndLoop("bulletSmallMob").setSpeed(0.3);
	}

	function onBulletHitObstacle() {
		fx.bulletWall(centerX, centerY, Math.atan2(dy,dx));
		destroy();
	}

	function checkHit(e:Entity, ?extraBounds=0) {
		return e.isAlive() && isAlive() && e!=source
			&& footX>=e.footX-3-extraBounds && footX<=e.footX+3+extraBounds
			&& footY>=e.headY+2-extraBounds && footY<=e.footY+extraBounds;
	}

	override function update() {
		super.update();
		if( level.hasCollision(cx,cy) ) {
			var a = Math.atan2(dy,dx);
			if( level.hasCollision(Std.int(cx+xr+Math.cos(a)*0.3), Std.int(cy+yr+Math.sin(a)*0.3)) )
				onBulletHitObstacle();
		}
		if( !level.isValid(cx,cy) )
			destroy();

		if( source.is(en.Mob) && checkHit(hero) ) {
			hero.hit(this, 1);
			fx.bulletBleed(centerX, centerY, Math.atan2(dy,dx));
			destroy();
		}
		for(e in Mob.ALL)
			if( checkHit(e,5) ) {
				e.hit(this, e.armor ? 1 : 3);
				e.stunS(2);
				fx.bulletBleed(centerX, centerY, Math.atan2(dy,dx));
				destroy();
			}
	}
}