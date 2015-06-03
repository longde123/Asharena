package alternativa.engine3d.utils 
{
	import flash.geom.Vector3D;
	/**
	 * ...
	 * @author Glenn Ko
	 */
	public class IntersectSlopeUtil 
	{
		 
        public var startPt:Vector3D = new Vector3D(30,60);
        public var endPt:Vector3D = new Vector3D();
        
        public var pt1:Vector3D = new Vector3D(100, 60, 60);
        public var pt2:Vector3D = new Vector3D(90, 60, 80);
        public var pt3:Vector3D = new Vector3D(70,180, 100);
        private var r:Number;
        private var s:Number;
		public var velocity:Vector3D = new Vector3D();
		public var startPosition:Vector3D = new Vector3D();
        
        public var intersectTimes:Vector.<Number> = new Vector.<Number>(2, true);
        public var intersectZ:Vector.<Number> = new Vector.<Number>(2, true);
		public var gradient:Number;
		
		public static const RESULT_NONE:int = 0;
		public static const RESULT_SLOPE:int = 1;
		public static const RESULT_WALL:int = -1;
		public static const RESULT_COLLINEAR:int = -2;
		
		        private var _tRise:Number;
        private var _h:Number;
		
        public function sqDistBetween2DVector(a:Vector3D, b:Vector3D):Number {
            var dx:Number = b.x - a.x;
            var dy:Number = b.y - a.y;
            return dx * dx + dy * dy;
        }
        
        public function rBetween2DVec(a:Vector3D, b:Vector3D, c:Vector3D):Number {
            var dx:Number = b.x - a.x;
            var dy:Number = b.y - a.y;
            var dx2:Number = c.x - a.x;
            var dy2:Number = c.y - a.y;
            return dx * dx2 + dy * dy2;
        }
		
		public function setupRay(origin:Vector3D, direction:Vector3D):void {
			startPt.x = origin.x;
			startPt.y = origin.y;
			startPt.z = origin.z;
			
			endPt.x = startPt.x + direction.x;
			endPt.y = startPt.y + direction.y;
			endPt.z = startPt.z + direction.z;
			
			
		}
		
		public function setupTri(ax:Number, ay:Number, az:Number, bx:Number, by:Number, bz:Number, cx:Number, cy:Number, cz:Number):void {
			pt1.x = ax;
			pt1.y = ay;
			pt1.z = az;
			
			pt2.x = bx;
			pt2.y = by;
			pt2.z = bz;
			
			pt3.x = cx;
			pt3.y = cy;
			pt3.z = cz;
		}
		
		public function getTriSlopeTrajTime(direction:Vector3D, gravity:Number, strength:Number):Number {
		//	gravity = -gravity;
			
			velocity.x = Math.sqrt(direction.x * direction.x + direction.y * direction.y);
			velocity.y = direction.z;
			velocity.z = 0;
			velocity.normalize();
			velocity.x *= strength;
			velocity.y *= strength;
			
			startPosition.x = -intersectTimes[0];//   2D Distance before start of slope....  startPt.x * direction.x + startPt.y * direction.y;
			
			startPosition.y = startPt.z - intersectZ[0]; //  height from start of slope ..  startPt.z;
		
			
			
			// test flat first
			gradient = 0;
			startPosition.x = 0;
			startPosition.y = 0;
			
			//return getTrajectoryTimeOfFlight(startPosition.y, velocity.y, g);
			return getTrajectoryTimeOfFlight2(startPosition.y, velocity.y, gravity);
		}
		
		   private  function getTrajectoryTimeOfFlight(yo:Number, vyo:Number,  g:Number ):Number {
   

            var tRise:Number = -vyo / g;
            _tRise = tRise;
            
           // 0 = yo + .5 * g * t * t + vyo * t
            var h:Number = yo + vyo*vyo/(2*g);

            _h = h;
            
            var tSink:Number = Math.sqrt(2*h/g) * (yo >= 0 ? 1 : -1); //+- quadratic 
        return tRise + tSink;
        
        //return vyo/g + Math.sqrt((2*yo  + vyo*2*t - 1*g*t*t)/g);
        
        //return vyo/g + Math.sqrt((2*yo  + vyo*2*t - 1*g*t*t)/g);
    }
		
		
		 private function getTrajectoryTimeOfFlight2(yo:Number, vyo:Number, g:Number):Number {
        
         
        //y(t) = yo + (vyo)*t - (g/2)t2
        //x(t) = vxo*t,
		
		
        
        var t1:Number = -vyo/g;
        var t2:Number = Math.sqrt( vyo * vyo + g * 2 * yo) / g;
        _tRise = t1;
        _h =  yo + vyo*vyo/(2*g);
    //    return t1 + t2;
        //y = yo +  (vyo * t - g / 2 * t * t);
        //x = vxo * t;    
        
        var slope:Number      =  gradient;// 0.0; // For line.
        var yIntercept:Number  = -startPosition.x * gradient;
        
        //y = Ax2 + Bx + C
        var A:Number  = g / 2; // For parabolla, quadratic function coefficients.
        var B:Number  = vyo;
        var C:Number  = -yo;

        var a:Number = 0.0; // For solving quadratic formula.
        var b:Number  = 0.0;
        var c:Number  = 0.0;

        var x1:Number  = 0.0; // Point(s) of intersection.
        var y1:Number  = 0.0;
        var x2:Number  = 0.0;
        var y2:Number  = 0.0;

        a = A;
        b = B + slope*velocity.x;
        c = C - yIntercept;
        
        

        var discriminant:Number = b * b - 4 * a * c;

        if(discriminant > 0.0)
        {
            x1 = (-b + Math.sqrt(discriminant)) / (2.0 * a);
            x2 = (-b - Math.sqrt(discriminant)) / (2.0 * a);

            y1 = slope * x1 + yIntercept;
            y2 = slope * x2 + yIntercept;


            return  x1 > x2 ? x1 : x2;
        
        }
        else if(discriminant == 0.0)
        {
            x1 = (-b) / (2.0 * a);

            y1 = slope * x1 + yIntercept;
            return x1;
        }
        
      //  throw new Error("A:" + [yo, vyo, g] + ", " + velocity + ", " + startPosition  + ", " + gradient);
		// A:1309.5262287828373,-0.07232929302656285,200, Vector3D(0.9973808065981006, -0.07232929302656285, 0), Vector3D(17979.298412078024, 1309.5262287828373, 0), 0.278275705392896
        return -1;
        
    }
		
		
		
		public function getTriIntersections():int {
			var gotIntersect:Boolean;
         
        
            var count:int = 0;
			
            gotIntersect = IsIntersecting(startPt, endPt, pt1, pt2);
            if (gotIntersect) {
              
                intersectTimes[count] = r;
                intersectZ[count] = pt2.z * s - pt1.z * s  + pt1.z;
                count++;
                
            }
            gotIntersect = IsIntersecting(startPt, endPt, pt2, pt3);
            if (gotIntersect) {
              
                intersectTimes[count] = r;
                intersectZ[count] = pt3.z * s - pt2.z * s  + pt2.z;
                count++;
            }
            
            gotIntersect = IsIntersecting(startPt, endPt, pt3, pt1);
            if (gotIntersect) {
                if (count <2) {
                   
                    intersectTimes[count] = r;
                    intersectZ[count] = pt1.z * s - pt3.z * s  + pt3.z;
                    count++;
                }
            }
            
           
            
            var dx:Number = endPt.x - startPt.x;
            var dy:Number  = endPt.y - startPt.y;
            
            var temp:Number = intersectTimes[0];
            var temp2:Number = intersectZ[0];
            
            if (intersectTimes[1] < temp ) {
                intersectTimes[0] = intersectTimes[1];
                intersectZ[0] = intersectZ[1];
                
                intersectTimes[1] = temp;
                intersectZ[1]=temp2;
            }
            
            
            if (count!=0) {
               
                
                var rd:Number = (intersectTimes[1] - intersectTimes[0]);
                dx *= rd;
                dy *= rd;
                rd  = Math.sqrt( dx * dx + dy * dy ); 
                if (count > 1) {
                    if (rd> 0) {
                      gradient = (intersectZ[1] - intersectZ[0]) / rd;
                    //  debugField.text = "penetrate dist:" + rd + ", gradient:"+gradient + ", "+intersectTimes;
						return RESULT_SLOPE;
                    }
                    else {
                       //  debugField.text = "Hit a fully vertical wall!:"+intersectTimes[0];
					   return RESULT_WALL;
                    }
                }
                else {
					// TODO: collinear gradient
					
                    //debugField.text = "Collinear case";
					return RESULT_COLLINEAR;
                }

            
            }
            else {
              // debugField.text = "No penetrate";
			  return RESULT_NONE;
            }
		}


        
        public function IsIntersecting(a:Vector3D, b:Vector3D, c:Vector3D, d:Vector3D):Boolean
        {
            var denominator:Number = ((b.x - a.x) * (d.y - c.y)) - ((b.y - a.y) * (d.x - c.x));
            var numerator1:Number = ((a.y - c.y) * (d.x - c.x)) - ((a.x - c.x) * (d.y - c.y));
            var numerator2:Number = ((a.y - c.y) * (b.x - a.x)) - ((a.x - c.x) * (b.y - a.y));

            // Detect coincident lines (has a problem, read below)
            if (denominator == 0) {
                // find between c and d, which is closer to a, clamp to s to 1 and 0, set r to c/d
               s = sqDistBetween2DVector(a, c) < sqDistBetween2DVector(a, d) ? 0 : 1;
               r = s != 0 ? rBetween2DVec(a, b, d)  : rBetween2DVec(a, b, c);
              // throw new Error("DETECT");
                return true;// (r >= 0) && (s >= 0 && s <= 1);
               //  return numerator1 == 0 && numerator2 == 0;
            }


            r = numerator1 / denominator;
            s = numerator2 / denominator;
            // && r <= 1
            return (r >= 0) && (s >= 0 && s <= 1);
        }
		
	}

}