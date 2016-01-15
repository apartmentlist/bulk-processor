shared_examples_for 'a role' do |role|
  role_class = BulkProcessor::Role.const_get(role)

  context "a #{role} role" do
    role_class.methods(false).each do |class_method|
      it "responds to .#{class_method}" do
        expect(described_class).to respond_to(class_method)
      end
    end

    role_class.instance_methods(false).each do |instance_method|
      it "responds to ##{instance_method}" do
        expect(described_class.instance_methods).to include(instance_method)
      end
    end
  end
end
