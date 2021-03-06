package alternativa.a3d.systems.hud 
{

	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Occluder;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.MeshSetClone;
	import alternativa.engine3d.objects.MeshSetClonesContainer;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.primitives.Plane;
	import alternativa.engine3d.utils.GeometryUtil;
	import alternativa.engine3d.utils.Object3DUtils;
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import haxe.Log;
	import util.SpawnerBundle;
	import util.geom.Vec3;
	import alternativa.engine3d.alternativa3d;
	use namespace alternativa3d;
	
	/**
	 * Test out plane orientation and 4 corners of each oriented target board.
	 * 
	 * @author Glidias
	 */
	public class TargetBoardTester extends System
	{
		private var position:Vec3;
		private var nodeList:NodeList;
		private var planes:MeshSetClonesContainer;
		private var corners:MeshSetClonesContainer;
		
		private var billboardMat:FillMaterial = new FillMaterial(0xFF0000, 0.5);
		private var cornerMat:FillMaterial = new FillMaterial(0x0000FF, 1);
		
		private var cameraObj:Object3D;
		
		public var testOccluder:Occluder;
		
		public function TargetBoardTester(scene:Object3D, position:Vec3, cameraObj:Object3D=null) 
		{
			this.cameraObj = cameraObj;
			this.position = position;
			var p:Plane = new Plane(1, 1, 1, 1, false, false);
			p.rotationX = -Math.PI * .5;  

	
			
			GeometryUtil.globalizeMesh(p);
			
			planes = new MeshSetClonesContainer(p, billboardMat );
			
			corners = new MeshSetClonesContainer(new Box(4,4,4,1,1,1, false), cornerMat );
			if (position == null) this.position = new Vec3();
			scene.addChild(planes);
			scene.addChild(corners);
			
			SpawnerBundle.uploadResourcesOf(planes);
			SpawnerBundle.uploadResourcesOf(corners);
		}
		
		override public function addToEngine (engine:Engine) : void {
			nodeList = engine.getNodeList(TargetBoardNode);
			
		}
		
		private var billboardMatrix:Matrix3D = new Matrix3D();
		private var rawData:Vector.<Number> = new Vector.<Number>(16, true);
		
		private function CreateBillboardMatrix(right:Vec3, up:Vec3, look:Vec3, pos:Vec3, width:Number, height:Number):Matrix3D {
			/*
			 * 
			 
				right.x, look.x, up.x, 0,
				right.y, look.y, up.y, 0,
				right.z, look.z, up.z, 0,
				targPos.x, targPos.y, targPos.z, 1
			 
			 */
			///*
			var matrix:Matrix3D = billboardMatrix;
			var rawData:Vector.<Number> = this.rawData;  
			rawData[0] = -right.x * width; rawData[1] =  -right.y * width; rawData[2] = -right.z * width; rawData[3] =  0;
			rawData[4] = look.x; rawData[5] = look.y; rawData[6] =  look.z; rawData[7] =  0;
			rawData[8] = up.x * height; rawData[9] = up.y * height; rawData[10] =  up.z * height;  rawData[11] =  0;
			rawData[12] = pos.x; rawData[13] =  pos.y; rawData[14] =  pos.z; rawData[15] = 1;
			
			matrix.copyRawDataFrom(rawData);
			/*
			-1,-8.742277657347586e-8,0,0,
			8.628069991800658e-8, -0.9869361519813538,0.16111187636852264,0,
			-1.4084847954620727e-8,0.16111187636852264,0.9869361519813538,0
			
1.0728003978729248,-519.7822875976563,-35224.23046875,1,

0.9869361519813538,-2.9326055472900237e-10,4.7247757789525835e-11,0,
-2.9326055472900237e-10,-0.9869361519813538,0.15900714695453644,0,
0,0.16111187636852264,0.9740429520606995,0,

-1.0728003978729248,-519.7822875976563,-35224.23046875,1
			*/
		
			
			//*/
			//fixMatrix.append(matrix);
			//fixMatrix.appendTranslation(pos.x, pos.y, pos.z);
			//throw new Error(fixMatrix.rawData);
			
			return matrix;
		}
		
		private var targPos:Vec3 = new Vec3();
		private var targRight:Vec3 = new Vec3();
		private var targUp:Vec3 = new Vec3();
		private var targLook:Vec3 = new Vec3();
		private var dv:Vec3 =  new Vec3();
		private var UP:Vec3 = new Vec3(0, 0, 1)
	
		private var RIGHT:Vec3 = new Vec3(1, 0, 0);
		
		private function logNumbers(arr:Array):void {
			var str:String = "";
			
			for (var i:int = 0; i < arr.length; i++) {
				var vec:Vector.<Number> = arr[i];
				var arr2:Array = [];
				for (var n:int = 0; n < vec.length; n++) {
					arr2.push( Number(Math.round(vec[n]/0.01) * 0.01).toFixed(2) );
				}
	
				str += arr2.join("|")+"___";
			}
			Log.trace(str);
		}
		
		
		override public function update(time:Number):void
		{
			if (cameraObj != null) {
				position.x = cameraObj.x;
				position.y = cameraObj.y;
				position.z = cameraObj.z;
			}
	
			//var totalSprites:int = 0;
			
			planes.numClones = 0;
			corners.numClones = 0;
			
			for (var n:TargetBoardNode = nodeList.head as TargetBoardNode; n != null; n = n.next as TargetBoardNode) {
				
				targPos.x = n.pos.x;
				targPos.y = n.pos.y;
				targPos.z = n.pos.z;
				var dx:Number = position.x - targPos.x;
				var dy:Number = position.y - targPos.y;
				var dz:Number = position.z - targPos.z;
				var sd:Number = dx * dx + dy * dy + dz * dz;
				var d:Number = Math.sqrt(sd);
				var di:Number = 1 / d;
				targLook.x = dx * di;
				targLook.y = dy * di;
				targLook.z = dz * di;
				//Vec3.writeCross(UP, targLook, targRight);
				//targRight.normalize();  // any way to avoid normalizing?
				targRight.x = UP.y * targLook.z -  UP.z * targLook.y;
				targRight.y = UP.z * targLook.x - UP.x * targLook.z;
				targRight.z = UP.x * targLook.y - UP.y * targLook.x;
				targRight.normalize();
				

				
				var sc:Number = 1 / targLook.z;		
				
				//targLook.z;
				
				Vec3.writeCross(targLook, targRight, targUp);
				//targUp.normalize();
				
				var sx:Number = n.size.x - 4;
				var sz:Number = n.size.z;
				/*  // center of mass size modifications
				var wh:Number = 42;
				sz = wh*.5;
				targPos.z += sz*.5;
				*/
		
				var p:MeshSetClone = planes.addNewOrAvailableClone();
				
				
				var m:Matrix3D;
				
				

				
				/*
				objectTransform = dummyObj.matrix.decompose();
				objectTransform[0].x = targPos.x;
				objectTransform[0].y = targPos.y;
				objectTransform[0].z = targPos.z;
				var v:Vector3D = objectTransform[1];
				v.x = Math.atan2(dz, Math.sqrt(dx*dx + dy*dy));
				v.y = 0;
				v.z = -Math.atan2(dx, dy);
				m = new Matrix3D();
				m.recompose(objectTransform);
				p.root.matrix = m;
				*/
				
				//var arr:Array = [];
				/*
				targRight.x = 1;
				targRight.y = 0;
				targRight.z = 0;
				targUp.x = 0;
				targUp.y = 0;
				targUp.z = 1;
				targLook.x = 0;
				targLook.y = 1;
				targLook.z = 0;
				*/
				//*/
				
				// z-locked right vector multiplied over ellipsoid.x (assumed same as ellipsoid.y), is used for horizontal extent
				// UP vector is used for vertical extent....
				
				// horizontal extent
				dummyVec.copyFrom(targRight);
				dummyVec.z = 0;
				dummyVec.normalize();
				dummyVec.scale(sx);
				
				
				
			
				
				// project right vector over horizontal/vertical extents to see which width to use
				dx = targRight.dotProduct(dummyVec);  
				dy = targRight.z * sz; 
				dx = dx < 0 ? -dx : dx;
				dy = dy < 0 ? -dy : dy;
				var w:Number = dx < dy ? dy : dx;
				
				// project up vector over horizontal/vertical extents to see which height to use
				
				
				dx = targUp.dotProduct(dummyVec); 
				dy = targUp.z * sz; 
				dx = dx < 0 ? -dx : dx;
				dy = dy < 0 ? -dy : dy;
				var h:Number = dx < dy ? dy : dx;
				
				h = h >= w ? h : w;  // always enforce square or tall rectangle always for target board
				
				//targPos.z += 27*.5;
				//h -= 27/n.size.z*2;
				p.root.matrix = m = CreateBillboardMatrix(targRight, targUp, targLook, targPos, w*2, h*2 );
			
				/*
				var data:Vector.<Number> = m.rawData;
				targRight.x = -data[0];
				targRight.y = -data[1];
				targRight.z = -data[2];
				targUp.x = data[8];
				targUp.y = data[9];
				targUp.z = data[10];
				*/
			
				//p.root.rotationY = 0;
				///*
				
				var t:Transform3D;
				var vx:Number;
				var vy:Number;
				var vz:Number;
				
				t = planes.localToCameraTransform;
			
				
				p = corners.addNewOrAvailableClone();
				p.root.x = targPos.x; p.root.y = targPos.y; p.root.z = targPos.z;
				p.root.x += targUp.x * h;
				p.root.y += targUp.y * h;
				p.root.z += targUp.z * h;
				p.root.x -= targRight.x * w;
				p.root.y -= targRight.y * w;
				p.root.z -= targRight.z * w;
				
				vx = p.root.x; vy = p.root.y; vz = p.root.z;
				p.root.x = t.a*vx + t.b*vy + t.c*vz + t.d;
				p.root.y = t.e*vx + t.f*vy + t.g*vz + t.h;
				p.root.z = t.i * vx + t.j * vy + t.k * vz + t.l;
				vx = p.root.x; vy = p.root.y; vz = p.root.z;
				
				t = planes.cameraToLocalTransform;
				vx = p.root.x; vy = p.root.y; vz = p.root.z;
				p.root.x = t.a*vx + t.b*vy + t.c*vz + t.d;
				p.root.y = t.e*vx + t.f*vy + t.g*vz + t.h;
				p.root.z = t.i * vx + t.j * vy + t.k * vz + t.l;
				
			
				p = corners.addNewOrAvailableClone();
				p.root.x = targPos.x; p.root.y = targPos.y; p.root.z = targPos.z;
				p.root.x -= targUp.x * h;
				p.root.y -= targUp.y * h;
				p.root.z -= targUp.z * h;
				p.root.x -= targRight.x * w;
				p.root.y -= targRight.y * w;
				p.root.z -= targRight.z * w;
				
				p = corners.addNewOrAvailableClone();
				p.root.x = targPos.x; p.root.y = targPos.y; p.root.z = targPos.z;
				p.root.x -= targUp.x * h;
				p.root.y -= targUp.y * h;
				p.root.z -= targUp.z * h;
				p.root.x += targRight.x * w;
				p.root.y += targRight.y * w;
				p.root.z += targRight.z * w;
				
				p = corners.addNewOrAvailableClone();
				p.root.x = targPos.x; p.root.y = targPos.y; p.root.z = targPos.z;
				p.root.x += targUp.x * h;
				p.root.y += targUp.y * h;
				p.root.z += targUp.z * h;
				p.root.x += targRight.x * w;
				p.root.y += targRight.y * w;
				p.root.z += targRight.z * w;
				
				
				if (testOccluder != null) {
					var areaSubtracted:Number =  testOccluder.clip( testOccluder.getDisposableTransformedFace(targPos, targUp, targRight, w, h, planes.localToCameraTransform)  );
					var area:Number = w * h * 4;
					if (areaSubtracted > 0) {
						Log.trace( int(areaSubtracted/area*100)+"% cover" );
					}
					else {
						Log.trace("Fully exposed");
					}
					
				}
			
				break;
	
			}
			
			

			
			
		}
		private var dummyVec:Vec3 = new Vec3();
		private var dummyObj:Object3D = new Object3D();
		private var objectTransform:Vector.<Vector3D>;
		
	}

}
import ash.ClassMap;
import ash.core.Node;
import components.Ellipsoid;
import components.Pos;

class TargetBoardNode extends Node {
	public var pos:Pos;
	public var size:Ellipsoid;
	
	public function TargetBoardNode() {
		
	}
	
	private static var _components:ClassMap;
	
	public static function _getComponents():ClassMap {
		if(_components == null) {
				_components = new ClassMap();
				_components.set(Pos, "pos");
				_components.set(Ellipsoid, "size");
			
		}
			return _components;
	}
}
