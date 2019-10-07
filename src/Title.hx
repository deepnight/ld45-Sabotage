class Title extends dn.Process {
	var img : h2d.Bitmap;
	// var blink : h2d.Bitmap;
	var color : h3d.Vector;
	var hero : HSprite;
	var parachute : HSprite;
	var birds : Array<{ e:HSprite, x:Float, y:Float }> = [];

	public function new() {
		super(Main.ME);
		createRootInLayers(Main.ME.root, Const.DP_UI);
		img = new h2d.Bitmap(hxd.Res.title.toTile(), root);

		Boot.ME.s2d.addEventListener( onEvent );
		// blink = new h2d.Bitmap(h2d.Tile.fromColor(0xffcc00) root);
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

	var done = false;
	function skip() {
		if( done )
			return;
		color.setColor(0xffcc44);
		done = true;
	}

	function onEvent(e:hxd.Event) {
		switch e.kind {
			case EPush: skip();
			case ERelease: skip();
			case EKeyDown: skip();
			case EKeyUp: skip();
			case _:
		}
	}

	override function onResize() {
		super.onResize();

		img.x = ( w()/Const.SCALE*0.5 - img.tile.width*0.5 );
	}

	var rseed = new dn.Rand(0);
	override function postUpdate() {
		super.postUpdate();

		parachute.x = img.x + 183 + Math.cos(ftime*0.030)*2;
		parachute.y = img.y + 31 + Math.sin(1+ftime*0.019)*3;

		hero.x = img.x + 230 + Math.cos(0.5+ftime*0.030)*2;
		hero.y = img.y + 114 + Math.sin(1.5+ftime*0.019)*3;

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
}