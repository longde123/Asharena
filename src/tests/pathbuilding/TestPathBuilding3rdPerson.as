package tests.pathbuilding
{
	import alternativa.a3d.collisions.CollisionBoundNode;
	import alternativa.a3d.controller.SimpleFlyController;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.RenderingSystem;
	import alternativa.engine3d.Template;
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.tick.FrameTickProvider;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import saboteur.spawners.JettySpawner;
	import saboteur.systems.PathBuilderSystem;
	import saboteur.util.GameBuilder3D;
	import spawners.arena.GladiatorBundle;
	import systems.collisions.EllipsoidCollider;
	import util.SpawnerBundle;
	/**
	 * ...
	 * @author Glenn Ko
	 */
	public class TestPathBuilding3rdPerson extends Sprite
	{
		public var engine:Engine;
		public var ticker:FrameTickProvider;
		
		private var _template3D:Template;
		private var jettySpawner:JettySpawner;
		private var _simpleFlyController:SimpleFlyController;
		
		public function TestPathBuilding3rdPerson() 
		{
			engine = new Engine();
			ticker = new FrameTickProvider(stage);
			

	
			addChild( _template3D = new Template());
			_template3D.cameraController = _simpleFlyController =  new SimpleFlyController( new EllipsoidCollider(4, 4, 4), null, stage, new Object3D, 22, _template3D.settings.cameraSpeedMultiplier, 1);
			//_template3d.settings.cameraSpeed *= 4;
			//_template3d.settings.cameraSpeedMultiplier *= 2;
			_template3D.addEventListener(Template.VIEW_CREATE, onReady3D);
			
			ticker.add(tick);
			ticker.start();
		}
		
		private function onReady3D(e:Event):void 
		{
			SpawnerBundle.context3D = _template3D.stage3D.context3D;
			_simpleFlyController.object = _template3D.camera;
			
			
			engine.addSystem( new PathBuilderSystem(_template3D.camera), 0 );
			
			GladiatorBundle;
			
			jettySpawner = new JettySpawner();
			var ent:Entity = jettySpawner.spawn(engine,_template3D.scene);
			_simpleFlyController.collidable = (ent.get(GameBuilder3D) as GameBuilder3D).collisionGraph;
			
			(e.currentTarget as IEventDispatcher).removeEventListener(e.type, onReady3D);
			engine.addSystem( new RenderingSystem(_template3D.scene), 2 );
			
			
		}
		
		public function tick(time:Number):void 
		{
			
			engine.update(time);
			_template3D.cameraController.update();
			_template3D.camera.render(_template3D.stage3D);
		}
		
	}

}