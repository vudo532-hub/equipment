# Test the format_audit_changes method with duplicate equipment_type fields
class MockAudit
  attr_accessor :audited_changes, :auditable_type
  def initialize(changes, type)
    @audited_changes = changes
    @auditable_type = type
  end
end

# Test case 1: Both equipment_type and equipment_type_ref_id present
audit1 = MockAudit.new({
  'equipment_type' => ['scanner', 'monitor'],
  'equipment_type_ref_id' => [1, 2]
}, 'ZamarEquipment')

puts 'Test 1 - Both fields present:'
puts ApplicationController.helpers.format_audit_changes(audit1)

# Test case 2: Only equipment_type_ref_id present
audit2 = MockAudit.new({
  'equipment_type_ref_id' => [1, 2]
}, 'ZamarEquipment')

puts '\nTest 2 - Only ref_id present:'
puts ApplicationController.helpers.format_audit_changes(audit2)

# Test case 3: Only equipment_type present
audit3 = MockAudit.new({
  'equipment_type' => ['scanner', 'monitor']
}, 'ZamarEquipment')

puts '\nTest 3 - Only equipment_type present:'
puts ApplicationController.helpers.format_audit_changes(audit3)