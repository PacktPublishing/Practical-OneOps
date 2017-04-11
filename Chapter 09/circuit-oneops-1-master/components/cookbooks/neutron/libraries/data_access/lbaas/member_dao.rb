require File.expand_path('../../../../libraries/requests/lbaas/member_request', __FILE__)
require File.expand_path('../../../../libraries/models/lbaas/member_model', __FILE__)

class MemberDao

  def initialize(tenant)
    fail ArgumentError, 'tenant is nil' if tenant.nil?

    @member_request = MemberRequest.new(tenant)
  end

  def create_member(loadbalancer_id, pool_id, member)
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?
    fail ArgumentError, 'pool_id is nil' if pool_id.nil? || pool_id.empty?
    fail ArgumentError, 'member is nil' if member.nil?

    options = member.serialize_optional_parameters
    response = @member_request.wait(loadbalancer_id).create_lbaas_member(pool_id, member.ip_address, member.protocol_port, member.subnet_id, options)
    if response[:'status'] == 201
      member_id = JSON.parse(response[:body])['member']['id']
    end

    return member_id
  end

  def get_members(pool_id)
    fail ArgumentError, 'pool_id is nil' if pool_id.nil? || pool_id.empty?

    response = @member_request.list_lbaas_members(pool_id)
    members_dto = JSON.parse(response[:body])['members']

    members = Array.new()
    members_dto.each do |member_dto|
      member = MemberModel.new(member_dto['address'], member_dto['protocol_port'], member_dto['subnet_id'],
                               member_dto['tenant_id'], member_dto['id'], member_dto['operating_status'])
      member.admin_state_up = (member_dto['admin_state_up'])
      member.weight = (member_dto['weight'])
      members.push(member)
    end

    return members
  end


  def delete_member(pool_id, member_id)
    fail ArgumentError, 'pool_id is nil' if pool_id.nil? || pool_id.empty?
    fail ArgumentError, 'member id is nil' if member_id.nil?

    response = @member_request.delete_lbaas_member(pool_id, member_id)
    return response[:'status'] == 204 || response[:'status'] == 404 ? true : false

  end
  def update_member(loadbalancer_id, pool_id, member_id, member)
    fail ArgumentError, 'loadbalancer_id is nil' if loadbalancer_id.nil? || loadbalancer_id.empty?
    fail ArgumentError, 'pool_id is nil' if pool_id.nil? || pool_id.empty?
    fail ArgumentError, 'member is nil' if member.nil?

    options = member.serialize_optional_parameters
    response = @member_request.wait(loadbalancer_id).update_lbaas_member(pool_id, member_id, options)
    if response[:'status'] == 204 || response[:'status'] == 200
      member_id = JSON.parse(response[:body])['member']['id']
    end

    return member_id
  end

end