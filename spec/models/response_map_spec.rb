# spec/models/response_map_spec.rb
require 'rails_helper'

RSpec.describe ResponseMap, type: :model do
  # Set up roles that will be assigned to instructor and participant users
  let!(:role_instructor) { Role.create!(name: 'Instructor') }
  let!(:role_participant) { Role.create!(name: 'Participant') }

  # Set up instructor, assignment, and participant records for testing associations
  let(:instructor) { Instructor.create!(role: role_instructor, name: 'Instructor Name', full_name: 'Full Instructor Name', email: 'instructor@example.com', password: 'password') }
  let(:assignment) { Assignment.create!(name: 'Test Assignment', instructor: instructor) }
  let(:user) { User.create!(role: role_participant, name: 'no name', full_name: 'no one', email: 'user@example.com', password: 'password') }
  let(:participant) { Participant.create!(user: user, assignment: assignment) }
  let(:team) { Team.create!(assignment: assignment) }
  let(:response_map) { ResponseMap.create!(assignment: assignment, reviewee: participant, reviewer: participant) }


  describe 'validations' do
    # Basic validation test to confirm a ResponseMap with valid attributes is considered valid
    it 'is valid with valid attributes' do
      expect(response_map).to be_valid
    end

    # Ensures that a ResponseMap without a reviewer_id is invalid
    it 'is not valid without a reviewer_id' do
      response_map.reviewer_id = nil
      expect(response_map).not_to be_valid
      expect(response_map.errors[:reviewer_id]).to include("can't be blank")
    end

    # Ensures that a ResponseMap without a reviewee_id is invalid
    it 'is not valid without a reviewee_id' do
      response_map.reviewee_id = nil
      expect(response_map).not_to be_valid
      expect(response_map.errors[:reviewee_id]).to include("can't be blank")
    end

    # Ensures that a ResponseMap without a reviewed_object_id is invalid
    it 'is not valid without a reviewed_object_id' do
      response_map.reviewed_object_id = nil
      expect(response_map).not_to be_valid
      expect(response_map.errors[:reviewed_object_id]).to include("can't be blank")
    end

    # Tests for invalid values in reviewer_id, reviewee_id, and reviewed_object_id
    it 'is not valid with an invalid reviewer_id' do
      response_map.reviewer_id = 'invalid_id'
      expect(response_map).not_to be_valid
    end

    it 'is not valid with an invalid reviewee_id' do
      response_map.reviewee_id = 'invalid_id'
      expect(response_map).not_to be_valid
    end

    it 'is not valid with an invalid reviewed_object_id' do
      response_map.reviewed_object_id = 'invalid_id'
      expect(response_map).not_to be_valid
    end

    # Ensure uniqueness validation works as expected
    it 'does not allow duplicate response maps with the same reviewee, reviewer, and reviewed_object' do
      # Using the same participant as both reviewer and reviewee
      ResponseMap.create(assignment: assignment, reviewee: participant, reviewer: participant)
  
      duplicate_response_map = ResponseMap.new(
        assignment: assignment,
        reviewee: participant,
        reviewer: participant
      )
      
      expect(duplicate_response_map).not_to be_valid
      expect(duplicate_response_map.errors[:reviewee_id]).to include("Duplicate response map is not allowed.")
    end
  end

  describe 'scopes' do
    let(:submitted_response) { Response.create!(map_id: response_map.id, response_map: response_map, is_submitted: true) }

    # Scope test for retrieving response maps for a specific team
    it 'retrieves response maps for a specified team' do
      expect(ResponseMap.for_team(participant.id)).to include(response_map)
    end

    # Scope test for retrieving response maps by reviewer
    it 'retrieves response maps by reviewer' do
      expect(ResponseMap.by_reviewer(participant.id)).to include(response_map)
    end

    # Scope test for retrieving response maps for a specified assignment
    it 'retrieves response maps for a specified assignment' do
      expect(ResponseMap.for_assignment(assignment.id)).to include(response_map)
    end

    # Scope test to check response maps with responses
    it 'retrieves response maps with responses' do
      submitted_response
      expect(ResponseMap.with_responses).to include(response_map)
    end

    # Scope test to check response maps with submitted responses only
    it 'retrieves response maps with submitted responses' do
      submitted_response
      expect(ResponseMap.with_submitted_responses).to include(response_map)
    end

    # Ensures non-submitted responses are not included in with_responses scope
    it 'does not include response maps without responses in with_responses' do
      expect(ResponseMap.with_responses).not_to include(response_map)
    end
  end
end
