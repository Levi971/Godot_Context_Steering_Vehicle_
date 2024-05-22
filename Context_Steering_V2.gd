@tool
extends Node3D
class_name Context_Steering

@export_flags_3d_physics var Raycast_See_Layers

@export var M = 1.0
@export var Change_Pow_With_Speed = false
@export var Pow_Longueur = 2.0
@export var At_Speed = 0.5
@export var Max_Pow_Longueur = 2.0
@export var Debug = false

var Debug_Lab = Label3D.new()

var Liste_des_ray = []
var Liste_des_interet = []
var Liste_des_danger = []
var Liste_des_nouvelle_distance = []
var Liste_des_ancienne_distance = []
var Ray_angle_doré = null

var Direction_voiture = Vector3.ZERO
var Direction_Target = Vector3.ZERO
var Direction_Souhaité = Vector3.ZERO
var Direction_Golden_Normal = Vector3.ZERO

var Left_Right_Input = 0
var Slow_Down = false
var Dodge_Left_Right_Input = 0
var Calculed_Left_Right_Input = 0

@export var Car : RigidBody3D
@export var Target : Node3D

@export var Nombre_Raycast = 8
@export var Angle_Opening = 90
@export var Raycast_Lenght = 8
@export var Danger_Value = 1.5
@export var Distance_Matter = false


@export var Create = false
@export var Remove = false



@export_category("Ray_Color")
@export var Thick = 5


# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		Creation_Ray()
		Debug_Lab.font_size = 50
		add_child(Debug_Lab)
		Debug_Lab.position.y += 3
		Debug_Lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		print(Liste_des_ray)

	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	print(Liste_des_ray)
	
	
	#if Create:
		#Creation_Ray()
		#Create = false
		
	if Remove:
		Delete_Ray()
		Remove = false
		
		
	
	
#	Input_Caluculation_Imaginaire()
	
	pass

func Creation_Ray():
	
	var Angle_Dore = Angle_Opening
	
	for i in Nombre_Raycast + 1:
		Liste_des_nouvelle_distance.append(0.0)
		Liste_des_ancienne_distance.append(0.0)
		var ratio_lerp = float(i) / float(Nombre_Raycast)
		var angle = lerpf(-Angle_Opening, Angle_Opening , ratio_lerp)
		
		var Ray = RayCast3D.new()
		Ray.rotation_degrees.y = angle
		
		#var Importance = absf(Ray.global_basis.z.dot(Car.global_basis.z))
		#
		#Ray.target_position = Vector3(0,0,(-Raycast_Lenght * Importance))
		Ray.collision_mask = Raycast_See_Layers
		

		Ray.debug_shape_thickness = Thick
		add_child(Ray)
		Ray.owner = get_tree().edited_scene_root
		Ray.name = str(int(angle))
		Liste_des_ray.append(Ray)
		
		
		var pro = -Ray.global_basis.z.dot(Car.global_basis.x)
		#pro = round(pro)
		
		if pro > 0:
			Ray.debug_shape_custom_color = Color.GREEN
		else:
			Ray.debug_shape_custom_color = Color.RED
		
		if absf(angle) == 0:
			Ray_angle_doré = Ray
			Ray.debug_shape_custom_color = Color.GOLD
			
		var Importance = absf(Ray.global_basis.z.dot(Car.global_basis.z))
		
		Ray.target_position = Vector3(0,0,(-Raycast_Lenght * pow(Importance, Pow_Longueur)))

func Delete_Ray():
	var enfants = get_children()

	for i in enfants.size():
		if enfants[i] is RayCast3D:
			remove_child(enfants[i])


func Processing(Direction : Vector3):
	
	var Final_Produit = Direction
	
	var Ray_qui_touche = 0
	var Ray_prit_en_compte = 0
	var Esquive = 0
	
	for i in Liste_des_ray.size():
		var Ray_ = Liste_des_ray[i]
		
		if Ray_ is RayCast3D:
			var Ratio = (Car.linear_velocity.length() / Car.get_parent().Max_Speed)
			var pow_Ratio = inverse_lerp(Car.get_parent().Max_Speed * At_Speed, Car.get_parent().Max_Speed , Car.linear_velocity.length())
			pow_Ratio = clampf(pow_Ratio,0,1)
			
			
			var Real_Pow_Longueur = lerpf(Pow_Longueur,Max_Pow_Longueur,pow_Ratio)
			Real_Pow_Longueur = clampf(Real_Pow_Longueur,1,1000)
			
			var Importance = absf(Ray_.global_basis.z.dot(Car.global_basis.z))
			Ray_.target_position = Vector3(0,0,((-Raycast_Lenght * Ratio) * pow(Importance, Real_Pow_Longueur)))
			
			Ray_.force_raycast_update()
			Ray_.force_update_transform()
			
			var Ray_Direction = -Ray_.global_basis.z
			
			var Prod = Ray_Direction.dot(-Car.global_basis.z)
			
			var Side = Ray_Direction.dot(Car.global_basis.x)
			
			
			
			
	
			#if Side > 0 : Side = -1
			#else: Side = 1
			
			if Side > 0 : Side = 1
			else: Side = -1
			
			
			
			if Ray_.is_colliding():
				
				Ray_qui_touche += 1
				
				var Importance_reduct = false
				
				if Ray_.get_collider().is_in_group("Car"):
					Importance_reduct = true
				
				
				
				var Dis_Imp = 1
				
				if Distance_Matter and Ray_ != Ray_angle_doré:
					Dis_Imp = 1 - ((Ray_.get_collision_point().distance_to(global_position)  / absf(Ray_.target_position.z)))
				
				Liste_des_nouvelle_distance[i] = Ray_.get_collision_point().distance_to(global_position)
				
				if Importance_reduct :
					Dis_Imp /= 8
				
				if Importance_reduct and ((Ray_.get_collision_point().distance_to(global_position)  / absf(Ray_.target_position.z))) > 0.2:
					Dis_Imp = 0
				
				if Ray_ == Ray_angle_doré:
					Side = Ray_.get_collision_normal().dot(Car.global_basis.x)
					
					#if Side > 0 : 
						#Side = 1.5
					#else: 
						#Side = -1.5
					#
					if Side > 0 : 
						Side = -1.5
					else: 
						Side = 1.5
				
				
				#if (Liste_des_nouvelle_distance[i] < (Liste_des_ancienne_distance[i] )) or (Liste_des_nouvelle_distance[i] < absf(Ray_.target_position.z / 2.0)):
				Final_Produit += (Car.global_basis.x * ((Prod * Side) * Dis_Imp) * Danger_Value)
				Ray_prit_en_compte += 1
				Esquive += (((Prod * Side) * Dis_Imp) * Danger_Value)
		
			if not Ray_.is_colliding():
				Liste_des_nouvelle_distance[i] = 9999
				
			Liste_des_ancienne_distance[i] = Liste_des_nouvelle_distance[i]
	
	#print (Liste_des_ancienne_distance)
	Debug_Lab.text = str("Ray_qui_touche = ", Ray_qui_touche)
	Debug_Lab.text += str("\n","Ray prit en compte = ", Ray_prit_en_compte)
	Debug_Lab.text += str("\n","Esquive = ", snappedf(Esquive,0.1))
	#Debug_Lab.text += str("\n","Liste_des_nouvelle_distance = ", Liste_des_nouvelle_distance)
	#Debug_Lab.text += str("\n","Liste_des_anciens_distance = ", Liste_des_ancienne_distance)
	
	return (Final_Produit.normalized())


func Processing_ver_2(Direction : Vector3):
	var Pure_Direction = Direction
	var Final_Produit = Direction
	
	var Ray_qui_touche = 0
	var Ray_prit_en_compte = 0
	var Esquive = 0
	
	for i in Liste_des_ray.size():
		var Ray_ = Liste_des_ray[i]
		
		if Ray_ is RayCast3D:
			var Ratio = (Car.linear_velocity.length() / Car.get_parent().Max_Speed)
			
			var Real_Pow_Longueur = lerpf(Pow_Longueur,Max_Pow_Longueur,Ratio)
			Real_Pow_Longueur = clampf(Real_Pow_Longueur,1,1000)
			
			var Importance = absf(Ray_.global_basis.z.dot(Car.global_basis.z))
			Ray_.target_position = Vector3(0,0,((-Raycast_Lenght )))
			
			Ray_.force_raycast_update()
			Ray_.force_update_transform()
			
			var Ray_Direction = -Ray_.global_basis.z
			
			var Prod = Ray_Direction.dot(-Car.global_basis.z)
			
			var Side = Ray_Direction.dot(Car.global_basis.x)
			
			var Interet = Ray_Direction.dot(Pure_Direction)
			

			#if Side > 0 : Side = -1
			#else: Side = 1
			
			if Side > 0 : Side = 1
			else: Side = -1

			if not Ray_.is_colliding():
				Final_Produit += Ray_Direction * Interet
			
			
			print(Ray_.name ,"    ",Interet)
				
				
				#Final_Produit += Ray_Direction * (Interet * Prod)
				
			#if Ray_.is_colliding():
				#
				#var Dis_Imp = 1 - ((Ray_.get_collision_point().distance_to(global_position)  / absf(Ray_.target_position.z)))
				#Final_Produit -= (Ray_Direction * Prod) * Dis_Imp
	
	#print (Liste_des_ancienne_distance)
	Debug_Lab.text = str("Ray_qui_touche = ", Ray_qui_touche)
	Debug_Lab.text += str("\n","Ray prit en compte = ", Ray_prit_en_compte)
	Debug_Lab.text += str("\n","Esquive = ", snappedf(Esquive,0.1))
	#Debug_Lab.text += str("\n","Liste_des_nouvelle_distance = ", Liste_des_nouvelle_distance)
	#Debug_Lab.text += str("\n","Liste_des_anciens_distance = ", Liste_des_ancienne_distance)
	
	return (Final_Produit.normalized())
