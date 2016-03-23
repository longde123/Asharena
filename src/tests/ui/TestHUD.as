package tests.ui
{
	import alternativa.a3d.collisions.CollisionBoundNode;
	import alternativa.a3d.controller.SimpleFlyController;
	import alternativa.a3d.controller.ThirdPersonController;
	import alternativa.a3d.cullers.BVHCuller;
	import alternativa.a3d.rayorcollide.TerrainITCollide;
	import alternativa.a3d.rayorcollide.TerrainRaycastImpl;
	import alternativa.a3d.systems.radar.RadarMinimapSystem;
	import alternativa.a3d.systems.text.FontSettings;
	import alternativa.a3d.systems.text.StringLog;
	import alternativa.a3d.systems.text.TextMessageSystem;
	import alternativa.a3d.systems.text.TextSpawner;
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.loaders.ParserA3D;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.objects.Hud2D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.MeshSetClone;
	import alternativa.engine3d.objects.MeshSetClonesContainer;
	import alternativa.engine3d.objects.MeshSetClonesContainerMod;
	import alternativa.engine3d.objects.Sprite3D;
	import alternativa.engine3d.RenderingSystem;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.engine3d.spriteset.materials.MaskColorAtlasMaterial;
	import alternativa.engine3d.spriteset.materials.SpriteSheet8AnimMaterial;
	import alternativa.engine3d.spriteset.materials.TextureAtlasMaterial;
	import alternativa.engine3d.spriteset.SpriteSet;
	import alternativa.engine3d.Template;
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.tick.FrameTickProvider;
	import assets.fonts.ConsoleFont;
	import com.bit101.components.ComboBox;
	import components.Pos;
	import components.Rot;
	import de.polygonal.motor.geom.primitive.AABB2;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.ui.Keyboard;
	import input.KeyPoll;
	import saboteur.models.PlayerInventory;
	import saboteur.spawners.JettySpawner;
	import saboteur.spawners.PickupItemSpawner;
	import saboteur.spawners.SaboteurHud;
	import saboteur.systems.PathBuilderSystem;
	import saboteur.systems.PlayerInventoryControls;
	import saboteur.util.GameBuilder3D;
	import saboteur.util.SaboteurPathUtil;
	import spawners.arena.GladiatorBundle;
	import systems.collisions.EllipsoidCollider;
	import systems.collisions.GroundPlaneCollisionSystem;
	import systems.SystemPriorities;
	import util.SpawnerBundle;
	import util.SpawnerBundleLoader;
	import views.engine3d.MainView3D;
	import views.ui.bit101.BuildStepper;
	import views.ui.bit101.PreloaderBar;
	import views.ui.indicators.CanBuildIndicator;
	import views.ui.UISpriteLayer;
	import alternativa.engine3d.alternativa3d;
	use namespace alternativa3d;
	/**
	 * Third person view and Spectator ghost flyer switching with wall collision against builded paths
	 * @author Glenn Ko
	 */
	public class TestHUD extends MovieClip
	{
		//public var engine:Engine;
		public var ticker:FrameTickProvider;
		public var game:TheGame;
		static public const START_PLAYER_Z:Number = 134;
		
		private var _template3D:MainView3D;
		
		private var uiLayer:UISpriteLayer = new UISpriteLayer();
		private var stepper:BuildStepper;
		private var thirdPerson:ThirdPersonController;
		
		private var bundleLoader:SpawnerBundleLoader;
		private var gladiatorBundle:GladiatorBundle;
		private var jettySpawner:JettySpawner;
		private var arenaSpawner:ArenaSpawner;
		private var _preloader:PreloaderBar = new PreloaderBar();
		
		private var spectatorPerson:SimpleFlyController;
		
		private var borderMeshset:MeshSetClonesContainerMod;
		
		[Embed(source="../../../resources/hud/linesegment2.a3d", mimeType="application/octet-stream")]
		private var LINE_SEGMENT:Class;

		
		public function TestHUD() 
		{
			haxe.initSwc(this);
			addChild(_preloader);
			
			game = new TheGame(stage);
	
			addChild( _template3D = new MainView3D() );
			_template3D.onViewCreate.add(onReady3D);
		//	addChild(uiLayer);
				
			
			_template3D.visible = false;
		}
		
		private function clampGeometryX(geometry:Geometry):void {
			var vec:Vector.<Number>  = geometry.getAttributeValues(VertexAttributes.POSITION);
			
			for (var i:int = 0; i < vec.length; i += 3) {
				vec[i] = Math.round(vec[i ]);
				vec[i+ 1] = Math.round(vec[i + 1]);
				vec[i+2] = Math.round(vec[i + 2]);
			//	if (vec[i] < 0) vec[i] = 0;
				//if (vec[i] > 1) vec[i] = 1;
				
			//	if (vec[i] < 0) vec[i] = 0;
			
			
			}
			//throw new Error(vec);
			geometry.setAttributeValues(VertexAttributes.POSITION, vec);
		}
		
		private function setupLineDrawer():void { 
				var parserA3D:ParserA3D = new ParserA3D();
			parserA3D.parse( new LINE_SEGMENT() );
			
					var borderItem:Mesh = parserA3D.objects[0] as Mesh || parserA3D.objects[1] as Mesh;
			
			borderItem.scaleX = 1;
			borderItem.scaleY = 1;
			borderItem.scaleZ = 1;
		//	clampGeometryX(borderItem.geometry);
			
		borderMeshset = new MeshSetClonesContainerMod(borderItem, new FillMaterial(0x00FF00, 1), 0, null, 1);
		borderMeshset.z = 132;
		SpawnerBundle.uploadResources(borderMeshset.getResources());
		
			 borderMeshset.numClones = 0;
			 _template3D.scene.addChild(borderMeshset);
			 var outliner:Vector.<int> = new <int>[0,0, 1,0 , 1,1, 0,1  ];
			 var total:int = outliner.length;
				 for (var i:int = 0; i < total; i+=2) {
					// outliner[i];
					// outliner[i + 1];
					var clone:MeshSetClone = borderMeshset.addNewOrAvailableClone();
					clone.root.x =  outliner[i] * 256;
					clone.root.y =  -outliner[i + 1] * 256;
					 clone.root.z =  0;// heightMapData[ outliner[i + 1] * _across + outliner[i]];
					 
					 var i2:int = i + 2;
					 if (i2 >= total) {
						 i2 = 0;
					 }
					  var x2:Number= outliner[i2] * 256;
						 var y2:Number = -outliner[i2 + 1] * 256;
							x2-= clone.root.x;
							y2 -= clone.root.y;
							var d:Number = 1;// x2 == 0 || y2 == 0 ? 1 : GKEdge.DIAGONAL_LENGTH;
							d *= 256;
							d = 1 / d;
							x2 *= d;
							y2 *= d;
							
							///*
							clone.root.rotationZ =  Math.atan2(y2, x2);
							clone.root.scaleX = 1 / d;
				}
		}
		
		
		
		private function onReady3D():void 
		{
			
			
			SpawnerBundle.context3D = _template3D.stage3D.context3D;
			
			gladiatorBundle = new GladiatorBundle(arenaSpawner = new ArenaSpawner(game.engine, game.keyPoll));
			jettySpawner = new JettySpawner();
			
			hudAssets = new SaboteurHud(game.engine, stage, game.keyPoll);
			pickupSpawner = new PickupItemSpawner(game.engine);
			
			bundleLoader = new SpawnerBundleLoader(stage, onSpawnerBundleLoaded, new <SpawnerBundle>[gladiatorBundle, jettySpawner, hudAssets, pickupSpawner]);
			bundleLoader.progressSignal.add( _preloader.setProgress );
			bundleLoader.loadBeginSignal.add( _preloader.setLabel );
		}
		
		private function onSpawnerBundleLoaded():void 
		{
			//game.gameStates.engineState.changeState("thirdPerson");
				
			_template3D.visible = true;
			removeChild(_preloader);			
			game.engine.addSystem( new RenderingSystem(_template3D.scene), SystemPriorities.render );
			

			
		
			gladiatorBundle.arenaSpawner.addGladiator(ArenaSpawner.RACE_SAMNIAN, stage, 0, 0, START_PLAYER_Z + 33).add( game.keyPoll );
		
		
			
			
			var pathBuilder:PathBuilderSystem = new PathBuilderSystem(_template3D.camera);
			 
			game.gameStates.thirdPerson.addInstance(pathBuilder).withPriority(SystemPriorities.render);
			//game.engine.addSystem(pathBuilder, SystemPriorities.postRender );
			pathBuilder.signalBuildableChange.add( onBuildStateChange);
			var canBuildIndicator:CanBuildIndicator = new CanBuildIndicator();
			addChild(canBuildIndicator);
			pathBuilder.onEndPointStateChange.add(canBuildIndicator.setCanBuild);
			
		
	
			thirdPerson = new ThirdPersonController(stage, _template3D.camera, new Object3D(), arenaSpawner.currentPlayer, arenaSpawner.currentPlayer, arenaSpawner.currentPlayerEntity);
			//game.engine.addSystem( thirdPerson, SystemPriorities.postRender ) ;
			game.gameStates.thirdPerson.addInstance(thirdPerson).withPriority(SystemPriorities.postRender);
			
		
			game.engine.addSystem(new TextMessageSystem(), SystemPriorities.render );
			game.gameStates.thirdPerson.addInstance( new GroundPlaneCollisionSystem(102, true) ).withPriority(SystemPriorities.resolveCollisions);
			
			BVHCuller;
		
			
			
			uiLayer.addChild( stepper = new BuildStepper());
			stepper.onBuild.add(pathBuilder.attemptBuild);
			stepper.onStep.add(pathBuilder.setBuildIndex);
			stepper.onDelete.add(pathBuilder.attemptDel);
			
			ticker = new FrameTickProvider(stage);
			ticker.add(tick);
			ticker.start();
			
		
			//_template3D.camera.orthographic = true;
			_template3D.camera.addChild( hud = new Hud2D() );
			hud.z = 1.1;
			
	

			
			_template3D.viewBackgroundColor = 0xDDDDDD;
	
		
			
			spriteSet = hudAssets.txt_chat.spriteSet;
			
				var bitmapData:BitmapData = jettySpawner.createBlueprintSheet(_template3D.camera, _template3D.stage3D, hud);
			//	addChild( new Bitmap(bitmapData));
				GameBuilder3D
				//jettySpawner.minimap.createJettyAt(0, 0, SaboteurPathUtil.getInstance().getIndexByValue(63),  );
				
				jettySpawner.minimap.addToContainer( hudAssets.radarGridHolder);
				jettySpawner.minimap.setCuller(hudAssets.circleRadarCuller);
			
				
			
			var ent:Entity = jettySpawner.spawn(game.engine,_template3D.scene, arenaSpawner.currentPlayerEntity.get(Pos) as Pos);

			jettySpawner.minimap.createJettyWithBuilder(63, (ent.get(GameBuilder3D) as GameBuilder3D) );
			pathBuilder.onBuildSucceeded.add(jettySpawner.minimap.createJettyWithBuilder);
			pathBuilder.onDelSucceeded.add(jettySpawner.minimap.removeJettyWithBuilder);
			
		

			var playerControls:PlayerInventoryControls = new PlayerInventoryControls(game.keyPoll, new PlayerInventory(), hudAssets, pathBuilder, jettySpawner.minimap, stage);
			game.gameStates.thirdPerson.addInstance(playerControls).withPriority(SystemPriorities.preRender);
			
			if (game.colliderSystem) {
				
				game.colliderSystem.collidable = (ent.get(GameBuilder3D) as GameBuilder3D).collisionGraph;
				game.colliderSystem._collider.threshold = 0.00001;
			}
			
			TerrainITCollide;
			TerrainRaycastImpl;
			
			spectatorPerson =new SimpleFlyController( 
						new EllipsoidCollider(GameSettings.SPECTATOR_RADIUS.x, GameSettings.SPECTATOR_RADIUS.y, GameSettings.SPECTATOR_RADIUS.z), 
						(ent.get(GameBuilder3D) as GameBuilder3D).collisionGraph ,
						stage, 
						_template3D.camera, 
							30*512*256/60/60, //GameSettings.SPECTATOR_SPEED,
						GameSettings.SPECTATOR_SPEED_SHIFT_MULT);
			
						game.gameStates.spectator.addInstance(spectatorPerson).withPriority(SystemPriorities.postRender);
						
						var radarSystem:RadarMinimapSystem;
						
			game.engine.addSystem(radarSystem = new RadarMinimapSystem( 1 / JettySpawner.SPAWN_SCALE * jettySpawner.minimap.pixelToMinimapScale, hudAssets.radarHolder, arenaSpawner.currentPlayerEntity.get(Rot) as Rot,  _template3D.camera, hudAssets.radarGridHolder, arenaSpawner.currentPlayerEntity.get(Pos) as Pos, _template3D.camera, hudAssets.radarGridMaterial.gridCoordinates, (ent.get(GameBuilder3D) as GameBuilder3D).startScene, hudAssets.radarGridSprite), SystemPriorities.preRender);
			radarSystem.setGridPixels(32, JettySpawner.H);
			
			
			game.gameStates.thirdPerson.addInstance(jettySpawner.minimap).withPriority(SystemPriorities.postRender);
			
			
			hudAssets.addToHud3D(hud);
			hudAssets.txt_chatChannel.appendSpanTagMessage('The quick brown <span u="2">fox</span> jumps over the lazy dog. The <span u="1">quick brown fox</span> jumps over the lazy <span u="3">dog</span>. The <span u="1">quick brown fox</span> jumps over the lazy dog.');
			setupLineDrawer();
		
			game.gameStates.engineState.changeState("thirdPerson");
			jettySpawner.minimap.setupBuildModelAndView(pathBuilder, pathBuilder.getCurBuilder(), hudAssets.radarBlueprintOverlay);  //
		
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false,1);
		
		}
		
		
		
		
		
		private function trim( s:String ):String
{
  return s.replace( /^([\s|\t|\n]+)?(.*)([\s|\t|\n]+)?$/gm, "" );
}
		
		
		
		private var _isThirdPerson:Boolean = true;
		private var spriteSet:SpriteSet;
		private var hudAssets:SaboteurHud;
		private var hud:Hud2D;
		private var pickupSpawner:PickupItemSpawner;
		private function onKeyDown(e:KeyboardEvent):void 
		{
				
			if (!game.keyPoll.disabled) {
				if (e.keyCode === Keyboard.L &&   !game.keyPoll.isDown(Keyboard.L)) { // && 
					
					_isThirdPerson = !_isThirdPerson;
					game.gameStates.engineState.changeState(_isThirdPerson ? "thirdPerson" : "spectator");
					
				}
				
				if (e.keyCode === Keyboard.U &&   !game.keyPoll.isDown(Keyboard.U)) { // && 
					
					if (	hudAssets.txt_chatChannel.getShowItems() == 5) {
						hudAssets.txt_chatChannel.setShowItems(12);
					}
					else hudAssets.txt_chatChannel.setShowItems(5);
				
				}
				
				if (e.keyCode === Keyboard.PAGE_UP &&   !game.keyPoll.isDown(Keyboard.PAGE_UP) ) {
					hudAssets.txt_chatChannel.scrollUpHistory();
				}
				else if (e.keyCode === Keyboard.PAGE_DOWN &&   !game.keyPoll.isDown(Keyboard.PAGE_DOWN)) {
					hudAssets.txt_chatChannel.scrollDownHistory();
				}
				else if  (e.keyCode === Keyboard.END &&   !game.keyPoll.isDown(Keyboard.END)) {
					hudAssets.txt_chatChannel.scrollEndHistory();
				}
				
				if (e.keyCode === Keyboard.BACKSLASH &&   !game.keyPoll.isDown(Keyboard.BACKSLASH)) { // && 
					hudAssets.txt_chatChannel.resetAllScrollingMessages();
					/*
					if (	hudAssets.txt_chatChannel.getShowItems() == 5) {
						hudAssets.txt_chatChannel.setShowItems(12);
					}
					else hudAssets.txt_chatChannel.setShowItems(5);
				*/
				}
			}
			if (e.keyCode === Keyboard.F11) {
				System.pauseForGCIfCollectionImminent();
				
			}
		}
		
	
		
		private function tick(time:Number):void {
			
			game.engine.update(time);
			_template3D.render();
		}
		
		private function onBuildStateChange(result:int):void 
		{
			stepper.buildBtn.enabled = result === SaboteurPathUtil.RESULT_VALID;
			stepper.delBtn.enabled = result === SaboteurPathUtil.RESULT_OCCUPIED;
		}
		
		
		
	}

}