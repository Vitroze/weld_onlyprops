
TOOL.Category = "Constraints"
TOOL.Name = "Souder (Seul les props)"

TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "left_1", stage = 1, op = 2 },
	{ name = "reload" }
}

if CLIENT then
	language.Add( "tool.vitroze_weld_onlyprop.name", "Souder (Seul les props)" )
	language.Add( "tool.vitroze_weld_onlyprop.desc", "Soude deux props ensemble" )
	language.Add( "tool.vitroze_weld_onlyprop.0", "Clic gauche sur un prop pour le sélectionner, puis clic gauche sur un autre prop pour les souder ensemble." )
	language.Add( "tool.vitroze_weld_onlyprop.1", "Clic gauche pour choisir la position de soudure, puis clic gauche pour souder." )
	language.Add( "tool.vitroze_weld_onlyprop.left", "Sélectionner un prop à souder" )
	language.Add( "tool.vitroze_weld_onlyprop.left_1", "Choisir la position de soudure" )
	language.Add( "tool.vitroze_weld_onlyprop.reload", "Désouder tous les props soudés" )
end


cleanup.Register( "vitroze_weld_onlyprops" )
CreateConVar( "sbox_maxvitroze_weld_onlyprops", "10", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Nombre maximum de soudure (Seul les props)" )
local vitroze_weld_maxonlyprop = CreateConVar("vitroze_weld_maxonlyprop", "2", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Nombre maximum sur un même prop (Seul les props)")

local function GetOwnerProp( ent )

	if ( not IsValid( ent ) ) then return nil end
	if ( ent:IsPlayer() ) then return nil end

	if istable(MPP) and MPP.owner then
		return MPP.owner(ent)
	end

	if ent.Getowning_ent and IsValid(ent:Getowning_ent()) then
		return ent:Getowning_ent()
	end

	if ent.CPPIGetOwner then
		local owner = ent:CPPIGetOwner()
		return owner
	end

	return nil

end

local function CanAccess( ent, ply )

	if not IsValid( ply ) or not ply:IsPlayer() then return false end
	if not IsValid( ent ) then return false end
	if ent:GetClass() ~= "prop_physics" then return false, "Ce n'est pas un prop." end
	if not IsValid(GetOwnerProp(ent)) or GetOwnerProp(ent) ~= ply then return false, "Vous n'êtes pas le propriétaire de ce prop." end
	if ply:GetPos():DistToSqr(ent:GetPos()) > 12000 then return false, "Le prop est trop éloigné de vous." end

	return true

end

local function DesactiveMotion( ent, delay )

	if delay == 0 then
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion( false )
		end

		return
	end

	timer.Simple( delay or 0, function()
		if IsValid(ent) then
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion( false )
			end
		end
	end)

end

function TOOL:LeftClick( trace )

	if ( self:GetOperation() == 1 ) then return false end

	local ply = self:GetOwner()
	if ply.CooldownWeldOnlyProp and ply.CooldownWeldOnlyProp > CurTime() then
		return false
	end

	ply.CooldownWeldOnlyProp = CurTime() + .25

	local bPassed, sError = CanAccess( trace.Entity, ply )
	if ( bPassed == false ) then

		if SERVER then
			DarkRP.notify(self:GetOwner(), 1, 4, sError or "Vous ne pouvez pas souder ce prop.")
		end

		return false

	end

	if ( not ply:CheckLimit( "vitroze_weld_onlyprops" ) ) then
		self:ClearObjects()
		return false
	end

	-- If there's no physics object then we can't constraint it!
	if ( SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	local iNum = self:NumObjects()
	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )

	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )

	if ( CLIENT ) then
		if ( iNum > 0 ) then self:ClearObjects() end
		return true
	end

	self:SetOperation( 2 )

	if ( iNum == 0 ) then

		self:SetStage( 1 )
		return true

	end

	if ( iNum == 1 ) then

		local Ent1, Ent2 = self:GetEnt( 1 ), self:GetEnt( 2 )

		if ( Ent1.VitrozeWeldOnlyPropCount and Ent1.VitrozeWeldOnlyPropCount > vitroze_weld_maxonlyprop:GetInt() ) or ( Ent2.VitrozeWeldOnlyPropCount and Ent2.VitrozeWeldOnlyPropCount > vitroze_weld_maxonlyprop:GetInt() ) then
			DarkRP.notify(ply, 1, 4, "Un des props a déjà atteint le nombre maximum de soudures.")
			self:ClearObjects()
			return false
		end

		if ( Ent1.VitrozeWeldTarget and Ent1.VitrozeWeldTarget == Ent2 ) or ( Ent2.VitrozeWeldTarget and Ent2.VitrozeWeldTarget == Ent1 ) then
			DarkRP.notify(ply, 1, 4, "Ces deux props sont déjà soudés ensemble.")
			self:ClearObjects()
			return false
		end

		if (Ent1:GetPos():DistToSqr(Ent2:GetPos()) > 8500) then
			DarkRP.notify(ply, 1, 4, "Les props sont trop éloignés pour être soudés.")
			self:ClearObjects()
			return false
		end

		if ( Ent1 == Ent2 ) then
			DarkRP.notify(ply, 1, 4, "Vous ne pouvez pas souder un prop à lui-même.")
			self:ClearObjects()
			return false
		end

		local Bone1, Bone2 = self:GetBone( 1 ), self:GetBone( 2 )

		local constr = constraint.Weld( Ent1, Ent2, Bone1, Bone2, 0, true, true )
		if ( IsValid( constr ) ) then

			undo.Create( "Weld - Only Props" )
				undo.AddEntity( constr )
				undo.SetPlayer( ply )
			undo.Finish( "Soudure - Seul les props" )

			local oPhys = Ent1:GetPhysicsObject()
			if ( IsValid( oPhys ) ) then
				oPhys:EnableMotion( false )
			end

			DesactiveMotion( Ent2 )

			constr:CallOnRemove( "VitrozeWeldOnlyPropRemove::" .. constr:EntIndex(), function( c )
				if IsValid( c.Ent1 ) then
					c.Ent1.VitrozeWeldOnlyPropCount = math.max((c.Ent1.VitrozeWeldOnlyPropCount or 1) - 1, 0)
					c.Ent1.VitrozeWeldTarget = nil

					DesactiveMotion( c.Ent1 )
				end

				if IsValid( c.Ent2 ) then
					c.Ent2.VitrozeWeldOnlyPropCount = math.max((c.Ent2.VitrozeWeldOnlyPropCount or 1) - 1, 0)
					c.Ent2.VitrozeWeldTarget = nil
					c.Ent2:SetCollisionGroup( COLLISION_GROUP_NONE )
					c.Ent2.bVitrozeWeldChildren = nil

					DesactiveMotion( c.Ent2 )
				end

			end )

			ply:AddCount( "vitroze_weld_onlyprops", constr )
			ply:AddCleanup( "vitroze_weld_onlyprops", constr )

			Ent1.VitrozeWeldOnlyPropCount = (Ent1.VitrozeWeldOnlyPropCount or 0) + 1
			Ent1.VitrozeWeldTarget = Ent2
			Ent2.VitrozeWeldOnlyPropCount = (Ent2.VitrozeWeldOnlyPropCount or 0) + 1
			Ent2.VitrozeWeldTarget = Ent1
			Ent2.bVitrozeWeldChildren = true

			Ent2:SetCollisionGroup( COLLISION_GROUP_WORLD )

			constr.Ent1 = Ent1
			constr.Ent2 = Ent2

			DarkRP.notify(ply, 0, 4, "Props soudés avec succès.")
		end

		-- Clear the objects so we're ready to go again
		self:ClearObjects()

	end

	return true

end

hook.Add("OnPlayerPhysicsDrop", "VitrozeWeldOnlyPropDrop", function(ply, ent)
	if IsValid(ent) and ent.VitrozeWeldTarget and ent.bVitrozeWeldChildren then
		ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
	end
end)

hook.Add("OnPhysgunPickup", "VitrozeWeldOnlyPropPickup", function(ply, ent)
	if IsValid(ent) and ent.VitrozeWeldTarget and ent.bVitrozeWeldChildren and ent:GetCollisionGroup() ~= COLLISION_GROUP_WORLD then
		ent:SetCollisionGroup( COLLISION_GROUP_NONE )
	end
end)

function TOOL:Reload( trace )

	local ply = self:GetOwner()
	if ply.CooldownWeldOnlyProp and ply.CooldownWeldOnlyProp > CurTime() then
		return false
	end
	ply.CooldownWeldOnlyProp = CurTime() + .25

	local eTarget = trace.Entity
	local bPassed, sError = CanAccess( eTarget, ply )
	if ( bPassed == false ) then
		DarkRP.notify(self:GetOwner(), 1, 4, sError or "Vous ne pouvez pas souder ce prop.")
		return false
	end

	if ( CLIENT ) then return true end

	self:ClearObjects()

	if ( eTarget.VitrozeWeldTarget ) then
		constraint.RemoveConstraints( eTarget, "Weld" )
		eTarget.VitrozeWeldTarget.VitrozeWeldOnlyPropCount = math.max((eTarget.VitrozeWeldTarget.VitrozeWeldOnlyPropCount or 1) - 1, 0)
		eTarget.VitrozeWeldTarget = nil
	end

	eTarget.VitrozeWeldOnlyPropCount = math.max((eTarget.VitrozeWeldOnlyPropCount or 1) - 1, 0)

	return constraint.RemoveConstraints( eTarget, "Weld" )

end

function TOOL:Holster()

	self:ClearObjects()

end

function TOOL.BuildCPanel( CPanel )

	CPanel:Help( "#tool.weld.help" )

end