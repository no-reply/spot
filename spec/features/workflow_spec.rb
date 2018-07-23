RSpec.feature 'One-Step Process Workflow' do
  subject(:publication) { build(:publication) }
  let(:ability)         { Ability.new(create(:user)) }
  let(:actor_stack)     { Hyrax::CurationConcern.actor }
  let(:attrs)           { {} }

  let(:actor_env) do
    Hyrax::Actors::Environment.new(publication, ability, attrs)
  end

  before do
    admin_set_id = AdminSet.find_or_create_default_admin_set_id
    workflow_id  = Sipity::Workflow.find_by!(name: 'spot_one_step_process').id

    Sipity::Workflow.activate!(
      permission_template: AdminSet.find(admin_set_id).permission_template,
      workflow_id: workflow_id
    )
  end

  before { actor_stack.create(actor_env) }

  it 'workflow is initialized as "spot_one_step_process"' do
    entity = PowerConverter.convert(publication, to: :sipity_entity)

    expect(entity.workflow)
      .to have_attributes name: 'spot_one_step_process'
  end

  shared_examples 'a commentable state' do
    it 'can be commented on'
  end

  context 'when in processing state' do
    it_behaves_like 'a commentable state'

    it 'can be approved'
    it 'is viewable to Spot users'
    it 'can be downloaded with a single use link'
  end

  context 'when in processed state' do
    it_behaves_like 'a commentable state'

    it 'is viewable to public users'
    it 'can be downloaded with a single use link'
  end
end
