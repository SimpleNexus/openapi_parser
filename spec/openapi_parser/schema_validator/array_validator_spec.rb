require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::SchemaValidator::ArrayValidator do
  let(:replace_schema) { {} }
  let(:root) { OpenAPIParser.parse(build_validate_test_schema(replace_schema), config) }
  let(:config) { {} }
  let(:target_schema) do
    root.paths.path['/validate_test'].operation(:post).request_body.content['application/json'].schema
  end
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }

  describe 'validate array' do
    subject { OpenAPIParser::SchemaValidator.validate(params, target_schema, options) }

    let(:params) { {} }
    let(:replace_schema) do
      {
        ids: {
          type: 'array',
          items: { 'type': 'integer' },
          maxItems: 2,
          minItems: 1,
          uniqueItems: true
        },
      }
    end

    context 'correct' do
      let(:params) { { 'ids' => [1] } }
      it { expect(subject).to eq({ 'ids' => [1] }) }
    end

    context 'invalid' do
      context 'max items breached' do
        let(:invalid_array) { [1,2,3,4] }
        let(:params) { { 'ids' => invalid_array } }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::MoreThanMaxItems)
            expect(e.message).to end_with("#{invalid_array} contains more than max items")
          end
        end
      end

      context 'min items breached' do
        let(:invalid_array) { [] }
        let(:params) { { 'ids' => invalid_array } }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::LessThanMinItems)
            expect(e.message).to end_with("#{invalid_array} contains fewer than min items")
          end
        end
      end

      context 'unique items breached' do
        let(:invalid_array) { [1, 1] }
        let(:params) { { 'ids' => invalid_array } }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::NotUniqueItems)
            expect(e.message).to end_with("#{invalid_array} contains duplicate items")
          end
        end
      end
    end
  end
end
