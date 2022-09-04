import Data;
import hxd.Key;

class Main extends dn.Process {
	public static var ME : Main;
	public var controller : Controller;
	public var ca : ControllerAccess;
	var overlay : dn.heaps.filter.OverlayTexture;

	public function new(s:h2d.Scene) {
		super();
		ME = this;

        createRoot(s);
        root.filter = new h2d.filter.ColorMatrix(); // force rendering for pixel perfect

		// Engine settings
		hxd.Timer.wantedFPS = Const.FPS;
		engine.backgroundColor = 0xff<<24|0x111133;
        #if( hl && !debug )
        engine.fullScreen = true;
        #end

		// Resources
		#if debug
		hxd.Res.initLocal();
        #else
        hxd.Res.initEmbed();
        #end

        // Hot reloading
		#if debug
        hxd.res.Resource.LIVE_UPDATE = true;
        hxd.Res.data.watch(function() {
            delayer.cancelById("cdb");

            delayer.addS("cdb", function() {
            	Data.load( hxd.Res.data.entry.getBytes().toString() );
            	if( Game.ME!=null )
                    Game.ME.onCdbReload();
            }, 0.2);
        });
		#end

		// Assets & data init
		hxd.snd.Manager.get();
		Lang.init("en");
		Assets.init();
		Data.load( hxd.Res.data.entry.getText() );

		// Console
		new ui.Console(Assets.fontTiny, s);

		// Game filter
		overlay = new dn.heaps.filter.OverlayTexture();
		Boot.ME.s2d.filter = overlay;
		overlay.alpha = 0.3;
		overlay.textureStyle = Soft;

		// Game controller
		controller = new Controller(s);
		ca = controller.createAccess("main");
		controller.bind(AXIS_LEFT_X_NEG, Key.LEFT, Key.Q, Key.A);
		controller.bind(AXIS_LEFT_X_POS, Key.RIGHT, Key.D);
		controller.bind(AXIS_LEFT_Y_NEG, Key.UP, Key.Z, Key.W);
		controller.bind(AXIS_LEFT_Y_POS, Key.DOWN, Key.S);
		controller.bind(A, Key.SPACE, Key.F, Key.E);
		controller.bind(B, Key.ESCAPE, Key.BACKSPACE);
		controller.bind(SELECT, Key.R);

		// Start
		new dn.heaps.GameFocusHelper(Boot.ME.s2d, Assets.fontMedium);
		delayer.addF( start, 1 );
	}

	function start() {
		// Music
		#if !debug
		Assets.playMusic();
		#end

		#if debug
		startGame();
		#else
		new Title();
		#end
	}

	public function startGame() {
		if( Game.ME!=null ) {
			Game.ME.destroy();
			delayer.addS(function() {
				new Game();
			},0.1);
		}
		else
			new Game();
	}

	override public function onResize() {
		super.onResize();

		// Auto scaling
		if( Const.AUTO_SCALE_TARGET_WID>0 )
			Const.SCALE = M.ceil( h()/Const.AUTO_SCALE_TARGET_WID );
		else if( Const.AUTO_SCALE_TARGET_HEI>0 )
			Const.SCALE = M.floor( h()/Const.AUTO_SCALE_TARGET_HEI );
		root.setScale(Const.SCALE);

		overlay.size = Std.int( Const.SCALE );
	}

    override function update() {
		Assets.tiles.tmod = tmod;

		if( ca.isKeyboardPressed(Key.M) )
			Assets.toggleMusicPause();
        super.update();
    }
}