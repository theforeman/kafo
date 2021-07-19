require 'test_helper'

describe 'Kafo::AnswerFile' do
  describe 'answer file version 1' do
    describe 'valid answer file' do
      let(:answer_file_path) { 'test/fixtures/answer_files/v1/basic-answers.yaml' }
      let(:answer_file) { Kafo::AnswerFile.load_answers(answer_file_path, 1) }

      it 'returns the sorted puppet classes' do
        _(answer_file.puppet_classes).must_equal(['class_a', 'class_b', 'class_c', 'class_d'])
      end

      it 'returns the parameters for a class' do
        _(answer_file.parameters_for_class('class_b')).must_equal({'key' => 'value'})
      end

      it 'returns true for a class with a hash' do
        _(answer_file.class_enabled?('class_c')).must_equal(true)
      end

      it 'returns true for a class set to true' do
        _(answer_file.class_enabled?('class_a')).must_equal(true)
      end

      it 'returns false for a class set to false' do
        _(answer_file.class_enabled?('class_d')).must_equal(false)
      end
    end

    describe 'invalid answer file' do
      let(:answer_file_path) { 'test/fixtures/answer_files/v1/invalid-answers.yaml' }

      it 'exits with invalid_answer_file' do
        _(Proc.new { Kafo::AnswerFile.load_answers(answer_file_path, 1) } ).must_raise Kafo::InvalidAnswerFile
      end
    end
  end
end
