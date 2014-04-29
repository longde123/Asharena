package arena.systems.enemy;
import alternativa.engine3d.core.Object3D;
import arena.components.char.HitFormulas;
import arena.components.char.MovementPoints;
import arena.components.enemy.EnemyAggro;
import arena.components.enemy.EnemyIdle;
import arena.components.enemy.EnemyWatch;
import arena.components.weapon.AnimAttackMelee;
import arena.components.weapon.PlayerAttack;
import arena.systems.player.IWeaponLOSChecker;

import arena.systems.player.PlayerAggroNode;
import ash.core.Engine;
import ash.core.Entity;
import ash.core.Node;
import ash.core.NodeList;
import ash.core.System;
import ash.fsm.EntityStateMachine;
import ash.signals.Signal1;
import ash.signals.Signal2;
import components.Ellipsoid;
import components.Pos;
import components.Rot;
import arena.components.weapon.Weapon;
import arena.components.weapon.WeaponState;
import util.geom.PMath;

/**
 * "Enemies" refer to the AI-controlled passive force entities in turn-based games, so they can refer to the friendly side 
 * during the enemy's turn. "Players" refer to the current "active" characters moving about in formation or solo. THeir movement points keep track of how much "time" they have moved, from which enemies can respond to that according to the time elapsed.
 * 
 * @author Glenn Ko
 */
class EnemyAggroSystem extends System implements IWeaponLOSChecker
{

	public var aggroList:NodeList<EnemyAggroNode>;
	public var watchList:NodeList<EnemyWatchNode>;
	public var idleList:NodeList<EnemyIdleNode>;
	private var playerNodeList:NodeList<PlayerAggroNode>;
	
	 // inline, so need to recompile
	private static inline var ROT_FACING_OFFSET:Float = HitFormulas.ROT_FACING_OFFSET; 
	private static inline var ROT_PER_SEC:Float = (220 * PMath.DEG_RAD);
	
	// states (coudl be factored out to model class);
	public var currentAttackingEnemy:Entity;
	
	public var onEnemyAttack:Signal1<Entity>;
	public var onEnemyReady:Signal1<Entity>;
	public var onEnemyStrike:Signal1<Entity>;
	public var onEnemyCooldown:Signal2<Entity, Float>;
	
	public static inline var AGGRO_HAS_CRITICAL:Bool = true;
	public var enemyCrit:Bool;
	public var updating:Bool;
	
	
	// Kiting AI exploit settings
	public static inline var ALLOW_KITE_RANGE:Int = 1;
	public static inline var ALLOW_KITE_OBSTACLES:Int = 2;
	public static inline var KITE_ALLOWANCE:Int = 0;
	
	private var _reactCooldown:Float;
	public static inline var REACT_TIME:Float = .215;  // Average reaction time of human being: 0.215 : 4.65 frames per second
	
	public function new() 
	{
		super();
		
		onEnemyAttack = new Signal1<Entity>();
		onEnemyReady = new Signal1<Entity>();
		onEnemyStrike = new Signal1<Entity>();
		
		onEnemyCooldown = new Signal2<Entity,Float>();
	}
	
	
	override public function addToEngine(engine:Engine):Void {
		aggroList = engine.getNodeList(EnemyAggroNode);
		watchList = engine.getNodeList(EnemyWatchNode);
		idleList = engine.getNodeList(EnemyIdleNode);
		
		playerNodeList = engine.getNodeList(PlayerAggroNode);
		playerNodeList.nodeRemoved.add(onPlayerNodeRemoved);
		
		_reactCooldown = 0;
		
		if (aggroList.head != null) throw "AGgro list isn't clean!";
		if (watchList.head != null) throw "watchList list isn't clean!";
		if (idleList.head != null) throw "idleList list isn't clean!";

	}
	
	//var boolTest:Bool;
	
	override public function removeFromEngine(engine:Engine):Void {
		currentAttackingEnemy = null;
		updating = false;
		
		// clean up all lists
		var i:EnemyIdleNode = idleList.head;  
		i = idleList.head;
		while ( i != null) {
			i.entity.remove(EnemyIdle);
			i = i.next;
		}
		
		
		var w:EnemyWatchNode = watchList.head;  
		while (w != null) {
				/*
				if (w.entity.get(WeaponState).trigger) {
					throw "SHOULD Not have trigger if on watch state!";
				}
				*/
				w.state.dispose();
				//w.entity.remove(EnemyWatch);
				//w.entity.add(EnemyIdle);
			w = w.next;
		}
		w = watchList.head;
		while ( w != null) {
			w.entity.remove(EnemyWatch);
			w = w.next;
		}
		//*/
		
		///*
		var a:EnemyAggroNode = aggroList.head;
		while (a != null) {
			
				
				a.weaponState.cancelTrigger();
				a.state.dispose();
				/*
				if (a.entity.get(WeaponState).trigger) {
					throw "SHOULD Not have trigger if out of aggro state!";
				}
				*/
				
			//	a.entity.remove(EnemyAggro); // TODO: Revert back to old watch condition
				
				a = a.next;
		}
		
		a = aggroList.head;
		while ( a != null) {
			a.entity.remove(EnemyAggro);
			a= a.next;
		}
		
		// should this be done!???
		watchList.removeAllNoSignal();
		playerNodeList.removeAllNoSignal();
		aggroList.removeAllNoSignal();
		idleList.removeAllNoSignal();
		
		
	//	if (boolTest) throw "CLEANED";
	//	boolTest = true;
	}
	
	
	// if for some reason, a player dies...
	function onPlayerNodeRemoved(node:PlayerAggroNode) 
	{
		node.movementPoints.timeElapsed = -1; // flag as "dead" using negative time elapsed (which is "impossible") 
		//throw "REMOVED";
		// remove all invalid nodes in watchList and aggroList where the target is found to have this playerAggroNode	
		// naively set state back to IDLE??? to force new search for any player node? Why not do the timeElapsed < 0 check for playerNode to determine if he is dead or not?...and if so, change target...or perhaps, change target from within here?
		
		/*
		var w:EnemyWatchNode = watchList.head;  
		while (w != null) {
			if (w.state.target == node) {
				
				w.entity.remove(EnemyWatch);
				w.entity.add(w.state.watch, EnemyIdle);
			}
			
			w = w.next;
		}
		

		
		var a:EnemyAggroNode = aggroList.head;
		while (a != null) {
			if (a.state.target == node) {
				
				

				a.weaponState.cancelTrigger();
				a.state.flag = 0;
				a.entity.remove(EnemyAggro); // TODO: Revert back to old watch condition
				a.entity.add(a.state.watch, EnemyIdle);
				a.state.dispose();
			}
			else throw "FOUDN!";
			a = a.next;
		}
		if (aggroList.head != null) throw "STILL HAV!";
		
		
		*/
	}
	
	// overwrite this method to include some form of ray-casting/occlusion detection algorithm to detect LOS visiblity
	
	public function validateVisibility(enemyPos:Pos, enemyEyeHeight:Float, playerNode:PlayerAggroNode):Bool {
		return true;
	}
	
	public function validateWeaponLOS(attacker:Pos, sideOffset:Float, heightOffset:Float, target:Pos, targetSize:Ellipsoid):Bool {
		return true;
	}

	
	
	private inline function getDestAngle(actualangle:Float, destangle:Float):Float {
		 var difference:Float = destangle - actualangle;
        if (difference < -PMath.PI) difference += PMath.PI2;
        if (difference > PMath.PI) difference -= PMath.PI2;
		return difference + actualangle;

	}
	
	private inline function getDiffAngle(actualangle:Float, destangle:Float):Float {
		 var difference:Float = destangle - actualangle;
        if (difference < -PMath.PI) difference += PMath.PI2;
        if (difference > PMath.PI) difference -= PMath.PI2;
		return difference;

	}
	
	private inline function getDestAngle2(actualangle:Float, destangle:Float, rotSpeed:Float):Float {
		
		 var difference:Float = destangle - actualangle;
		
        if (difference < -PMath.PI) difference += PMath.PI2;
        if (difference > PMath.PI) difference -= PMath.PI2;

		var t:Float = rotSpeed/PMath.abs(difference);
		if (t > 1) t = 1;
		
		destangle= actualangle + difference;
		
		return  PMath.slerp(actualangle, destangle, t);

	}
	
	private inline function getDestAngle2D(actualangle:Float, destangle:Float, rotSpeed:Float, difference:Float):Float {
		var t:Float = rotSpeed/PMath.abs(difference);
		if (t > 1) t = 1;
		
		destangle= actualangle + difference;
		
		return  PMath.slerp(actualangle, destangle, t);
	}
	
	private inline function getDestAngleDirection(actualangle:Float, destangle:Float):Float {
		 var difference:Float = destangle - actualangle;
        if (difference < -PMath.PI) difference += PMath.PI2;
        if (difference > PMath.PI) difference -= PMath.PI2;
		return difference*difference > .0005 ? difference > 0 ? 1 : -1 : 0;

	}
	

	override public function update(time:Float):Void {
		var swinger:AnimAttackMelee;
		updating = true;
		
		var p:PlayerAggroNode;
		currentAttackingEnemy = null;
		
		if (playerNodeList.head == null) return;
		
		p = playerNodeList.head;
		
		
		
		var playerPos:Pos = p.pos;
		var enemyPos:Pos;
		var dx:Float;
		var dy:Float;
		var dz:Float;
		
		var pTimeElapsed:Float = p.movementPoints.timeElapsed;
		
		
		if (pTimeElapsed <= 0) return; // being a turn based game, time only passes when player moves
		
		_reactCooldown -= pTimeElapsed;
		
		var gotReact:Bool = _reactCooldown <= 0;
		 _reactCooldown += gotReact ? REACT_TIME : 0;
		
		var i:EnemyIdleNode = gotReact  ? idleList.head : null;
		var rangeSq:Float;
		
		while (i != null) {  // assign closest player target to watch
			enemyPos = i.pos;
			rangeSq = i.state.alertRangeSq;
			dx =  playerPos.x - enemyPos.x;
			dy = playerPos.y - enemyPos.y;
			dz = playerPos.z - enemyPos.z;
			if (dx * dx + dy * dy + dz*dz <= rangeSq && HitFormulas.targetIsWithinFOV2(dx, dy, i.rot, i.state.fov) && validateVisibility(enemyPos, i.state.eyeHeightOffset, p) ) {  // TODO: Include rotation facing direction as a factor for EnemyIdle case to allow backstabs
				i.entity.remove(EnemyIdle);
				
				i.entity.add(new EnemyWatch().init(i.state,p), EnemyWatch); // TODO: Pool ENemyWatch
			}
			i = i.next;
		}
		
	
		var newAggro:EnemyAggro;
		var rangeToAttack:Float;
		
		var w:EnemyWatchNode = gotReact   ? watchList.head : null;
		while (w != null) {  // check closest valid player target, if it's same or different..  and consider aggroing if player gets close enough, 
			enemyPos = w.pos;
			
			rangeSq = w.state.watch.aggroRangeSq;
			dx =  playerPos.x - enemyPos.x;
			dy = playerPos.y - enemyPos.y;
			dz = playerPos.z - enemyPos.z;
			
			if (dx * dx + dy * dy + dz*dz <= rangeSq && validateVisibility(enemyPos, w.state.watch.eyeHeightOffset, p) ) { 
				
				w.entity.remove(EnemyWatch);
				newAggro = new EnemyAggro();
				rangeToAttack = ((ALLOW_KITE_RANGE & KITE_ALLOWANCE) != 0) ? HitFormulas.rollRandomAttackRangeForWeapon(w.weapon,p.size) : w.weapon.range + p.size.x;// w.weapon.critMaxRange + Math.random() * ( w.weapon.range - w.weapon.critMaxRange); 
				newAggro.setAttackRange( rangeToAttack);
				newAggro.watch = w.state.watch;
				newAggro.target = w.state.target;
				
				w.entity.add(newAggro, EnemyAggro);
				
			}
			
			w = w.next;
		}
		
	
		
		var a:EnemyAggroNode = aggroList.head; 
		var aWeaponState:WeaponState; 
		var aWeapon:Weapon;
		while (a != null) { 
			
			aWeaponState = a.weaponState;
			
			aWeapon = a.weapon;
			var pTarget:PlayerAggroNode = a.state.target;
			pTimeElapsed = pTarget.movementPoints.timeElapsed;
			
			
			dx = pTarget.pos.x - a.pos.x;
			dy = pTarget.pos.y - a.pos.y;
			dz =  pTarget.pos.z - a.pos.z;
			var sqDist:Float = dx * dx + dy * dy + dz*dz;
	
			
			// NAive canceling of attack trigger can be done since this isn't a real-time game, and pple wouldnt notice.
			if (pTimeElapsed < 0) { // player is dead, find new player to aggro for multi-character mode
				//throw "DEAD";
				
				// for single-character mode, since player is dead, everything's safe!
				a.state.flag = 0;
				aWeaponState.cancelTrigger();
				a.entity.remove(EnemyAggro);
				a.entity.add(a.state.watch); // TODO: Pool ENemyWatch
				
				
				a = a.next;
					continue;
			}
			else {  // find nearest valid target , if it's diff or not, and change accordingly
				// consider if player is out of aggro range to go back to watch
				rangeSq = a.state.watch.aggroRangeSq + 40;  // the +40 threshold should be a good enough measure to prevent oscillation
				///*
				if (sqDist > rangeSq) {  
					// revert back for now, forget about finding another target
					
					aWeaponState.cancelTrigger();
					a.state.flag = 0;
					a.entity.remove(EnemyAggro);
					a.entity.add(new EnemyWatch().init(a.state.watch, a.state.target, true), EnemyWatch); // TODO: Pool ENemyWatch
					
					a = a.next;
					continue;
				}
				//*/
			}
			
		
			
			// always rotate enemy to face player target

			var targRotZ:Float =  Math.atan2(dy, dx) + ROT_FACING_OFFSET;
		//	targRotZ = getDestAngle(a.rot.z, targRotZ);
			
			var diffAngle:Float = getDiffAngle(a.rot.z, targRotZ);
			a.rot.z = getDestAngle2D(a.rot.z, targRotZ, ROT_PER_SEC * pTimeElapsed, diffAngle);  // getDestAngleDirection(a.rot.z, targRotZ)  * (2 * PMath.DEG_RAD) * pTimeElapsed;
			diffAngle = PMath.abs( diffAngle);
			
			// determine if within "suitable" range to strike/engage player
			///*
			if (aWeaponState.trigger) {  // if attack was triggered, 
				if (aWeaponState.cooldown > 0) {  // weapon is on the  cooldown after strike has occured
					
					aWeaponState.cooldown -= pTimeElapsed;
					if (aWeaponState.cooldown <= 0) {  // cooldown finished. allow trigger to  be pulled again
						aWeaponState.cancelTrigger();
						a.state.flag = 0;
						a.state.setAttackRange( (((ALLOW_KITE_RANGE & KITE_ALLOWANCE) != 0) ? HitFormulas.rollRandomAttackRangeForWeapon(a.weapon, p.size) : a.weapon.range + p.size.x ) );
						onEnemyReady.dispatch(a.entity);
					}
					else {
						a.state.flag = 3;
						
						onEnemyCooldown.dispatch(a.entity, aWeaponState.cooldown);
					}
					
					
				}
				else {  // weapon is not on cooldown, but swinging
					//if (a.state.target.health.hp <= 0 ) throw "PLAYER already dEAD!";
					
					//if (aWeaponState.cooldown < 0) throw "SHOULD NOT BE2222!";
					
					aWeaponState.attackTime  += pTimeElapsed;
					var actualDist:Float = Math.sqrt(sqDist) - p.size.x;
					var strikeTimeAtRange:Float = HitFormulas.calculateStrikeTimeAtRange(aWeapon, actualDist);
					
					
					
					if ( aWeaponState.attackTime >= strikeTimeAtRange) { // strike has occured
						currentAttackingEnemy = a.entity;
						var kite:Int = (ALLOW_KITE_RANGE | ALLOW_KITE_OBSTACLES);
						
						// TODO: Also Consider weapon LOS as well, if either test fails (or perhaps LOS only..), considered kited miss OR "silent-cancel"?
						if (actualDist <= aWeapon.range && validateWeaponLOS(a.pos, a.weapon.sideOffset, a.weapon.heightOffset, p.pos, p.size)  ) {  // strike hit! 
							
							if (Math.random() * 100 <= HitFormulas.getPercChanceToHitDefender(a.pos, a.ellipsoid, a.weapon, p.pos, p.rot, p.def, p.size)) {
							
								// TODO: if strike occurs  
								
								//aWeaponState.attackTime = aWeapon.strikeTimeAtMaxRange;
								// deal damage to player heath
								//currentAttackingEnemy = a.entity;
								if (AGGRO_HAS_CRITICAL) {
									enemyCrit = false;
									if ( Math.random() * 100 <= HitFormulas.getPercChanceToCritDefender(a.pos, a.ellipsoid, a.weapon, p.pos, p.rot, p.def, p.size) ) {
										
										enemyCrit = true;
									}
								}
								a.signalAttack.forceSet(PlayerAttack.SWING);
								swinger =  new AnimAttackMelee();
								swinger.init_i_static( a.weapon.anim_strikeTimeAtMaxRange, p.health, HitFormulas.rollDamageForWeapon(aWeapon)*(enemyCrit ? 3 : 1) );
								a.entity.add(swinger);
								//p.health.damage(HitFormulas.rollDamageForWeapon(aWeapon)*(enemyCrit ? 3 : 1) );
								
							}
							else { // strike rolled miss
								a.signalAttack.forceSet(PlayerAttack.SWING);
								swinger =  new AnimAttackMelee();
								//HitFormulas.calculateAnimStrikeTimeAtRange(a.weapon, actualDist)
								swinger.init_i_static(a.weapon.anim_strikeTimeAtMaxRange, p.health, 0 );
								a.entity.add(swinger);
								
								//p.health.damage(0);
							}
							
							
						}
						else {  // considered possible forced strike miss (or silent cancel attack) due to evading blow... 

							kite = actualDist > aWeapon.range ? ALLOW_KITE_RANGE : (ALLOW_KITE_RANGE | ALLOW_KITE_OBSTACLES);
							kite &= KITE_ALLOWANCE;
							
							if (kite != 0) {  // somehow, kiting is allowed in this situation. Simulate deliberate swing miss.
								a.signalAttack.forceSet(PlayerAttack.SWING);
								swinger =  new AnimAttackMelee();
								swinger.init_i_static(a.weapon.anim_strikeTimeAtMaxRange, p.health, 0 );
								a.entity.add(swinger);
							}
							else { // no kiting allowed in this suitation. Silently cancel attack.
								a.state.flag = 0;
								a.weaponState.cancelTrigger();
							}
						}
						
						// boiler checks
						if (kite != 0) {
							if  (a.state.flag != 1) throw "State before strke isn't 1:!" + (a.entity.get(Object3D).name) + ":" + a.state.flag + ", " + aWeaponState.cooldown + ", "+strikeTimeAtRange + ", "+aWeaponState.trigger + ", "+aWeaponState.attackTime;
							if (a.state.flag == 2) throw "Repeat state 2!";
							aWeaponState.cooldown = aWeapon.cooldownTime;  
							a.state.flag = 2;
							onEnemyStrike.dispatch(a.entity);
						}
						
						
					
						
						
					}
				
				}
			}
			else {   // consider whether should pull trigger
			
				if (gotReact &&  HitFormulas.targetIsWithinArcAndRangeSq2(diffAngle, a.weapon.hitAngle, sqDist, a.state.attackRangeSq) && validateWeaponLOS(a.pos, a.weapon.sideOffset, a.weapon.heightOffset, p.pos, p.size)  ) {  // TODO: Weapon LOS check
				
					aWeaponState.pullTrigger();
					
					a.state.flag = 1;
					onEnemyAttack.dispatch(a.entity);
					
				}
			}
			//*/

			// Weapon summary
			
			// if got weapon state attacking, continue to tick it down, and finally determine hit/miss or cancel if target is already dead 

			// else if within range, attempt to trigger attack via weaponState
			
			// if hit/miss already determined or not attacking anymore, continue to find nearer target to aggro, , and if not so and current target is invalid or already dead, find another target within watch distance and reevert back to old watch state for that target. If no target found within watch distance, need to revert back to  idle state.
			
			a = a.next;
		}
		
		
		
		
		
	}
	
}




