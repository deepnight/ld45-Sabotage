class Title extends dn.Process {
	var img : h2d.Bitmap;
	// var blink : h2d.Bitmap;
	var color : h3d.Vector;
	var hero : HSprite;
	var parachute : HSprite;
	var birds : Array<{ e:HSprite, x:Float, y:Float }> = [];
	public var ca : dn.heaps.Controller.ControllerAccess;
	var heroX = 0.;
	var heroY = 0.;

	public function new() {
		super(Main.ME);

		ca = Main.ME.controller.createAccess("title", false);

		createRootInLayers(Main.ME.root, Const.DP_UI);
		img = new h2d.Bitmap(hxd.Res.title.toTile(), root);

		cd.setS("lock",0.2);
		color = new h3d.Vector();
		color.setColor(0xe5ae00);
		img.colorAdd = color;

		parachute = Assets.tiles.h_getAndPlay("parachute", root);
		parachute.colorAdd = color;

		hero = Assets.tiles.h_getAndPlay("heroGlide", root);
		hero.anim.setSpeed(0.4);
		hero.colorAdd = color;

		birds.push({ e:Assets.tiles.h_getAndPlay("bird"), x:360, y:85 });
		birds.push({ e:Assets.tiles.h_getAndPlay("bird"), x:322, y:104 });
		birds.push({ e:Assets.tiles.h_getAndPlay("bird"), x:360, y:114 });
		birds.push({ e:Assets.tiles.h_getAndPlay("bird"), x:290, y:77 });
		birds.push({ e:Assets.tiles.h_getAndPlay("bird"), x:281, y:87 });

		for(b in birds) {
			root.addChild(b.e);
			b.e.setCenterRatio(0.5,0.5);
			b.e.anim.setSpeed(rnd(0.3, 0.4));
			b.e.colorAdd = color;
		}

		dn.Process.resizeAll();
	}

	override function onDispose() {
		super.onDispose();
		ca.dispose();
	}

	var done = false;
	function skip() {
		if( done )
			return;
		color.setColor(0xffcc44);
		done = true;
	}

	override function onResize() {
		super.onResize();

		img.x = ( w()/Const.SCALE*0.5 - img.tile.width*0.5 );
	}

	var rseed = new dn.Rand(0);
	override function postUpdate() {
		super.postUpdate();

		parachute.x = heroX + img.x + 183 + Math.cos(ftime*0.030)*2;
		parachute.y = heroY + img.y + 31 + Math.sin(1+ftime*0.019)*3;

		hero.x = heroX + img.x + 230 + Math.cos(0.5+ftime*0.030)*2;
		hero.y = heroY + img.y + 114 + Math.sin(1.5+ftime*0.019)*3;

		rseed.initSeed(0);
		for(b in birds) {
			b.e.x = img.x + b.x + Math.cos(rseed.rand()*6.28 + ftime * rseed.range(0.01,0.04) * rseed.sign() )*rseed.irange(1,2);
			b.e.y = img.y + b.y + Math.sin(rseed.rand()*6.28 + ftime * rseed.range(0.01,0.04) * rseed.sign() )*rseed.irange(1,2);
		}

		if( !done ) {
			color.r*=Math.pow(0.99,tmod);
			color.g*=Math.pow(0.96,tmod);
			color.b*=Math.pow(0.98,tmod);
		}
		else {
			heroX+=0.3*tmod;
			heroY+=0.1*tmod;
			var s = 0.01;
			color.r = M.fmax(-1, color.r - s*tmod );
			color.g = M.fmax(-1, color.g - s*tmod );
			color.b = M.fmax(-1, color.b - s*tmod );
			if( color.r<=-1 && color.g<=-1 && color.b<=-1 ) {
				Main.ME.startGame();
				destroy();
			}
		}
	}

	override function update() {
		super.update();

		if( !cd.has("lock") ) {
			if( ca.isKeyboardPressed(hxd.Key.ESCAPE) )
				hxd.System.exit();

			if( ca.isKeyboardPressed(hxd.Key.ENTER) )
				hxd.System.exit();

			if( ca.aPressed() || ca.bPressed() || ca.xPressed() || ca.yPressed()
				|| ca.selectPressed() || ca.startPressed() )
					skip();
		}
	}
}