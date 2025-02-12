# frozen_string_literal: true

require "rails_helper"

RSpec.describe SolidusPromotions::PromotionCodeBatch, type: :model do
  subject do
    described_class.create!(
      promotion_id: create(:solidus_promotion).id,
      base_code: "abc",
      number_of_codes: 1,
      error: nil,
      email: "test@email.com"
    )
  end

  describe "#process" do
    context "with a pending code batch" do
      it "calls the worker" do
        expect { subject.process }
          .to have_enqueued_job(SolidusPromotions::PromotionCodeBatchJob)
      end

      it "updates the state to processing" do
        subject.process

        expect(subject.state).to eq("processing")
      end
    end

    context "with a processing batch" do
      before { subject.update_attribute(:state, "processing") }

      it "raises an error" do
        expect { subject.process }.to raise_error described_class::CantProcessStartedBatch
      end
    end

    context "with a completed batch" do
      before { subject.update_attribute(:state, "completed") }

      it "raises an error" do
        expect { subject.process }.to raise_error described_class::CantProcessStartedBatch
      end
    end

    context "with a failed batch" do
      before { subject.update_attribute(:state, "failed") }

      it "raises an error" do
        expect { subject.process }.to raise_error described_class::CantProcessStartedBatch
      end
    end
  end
end
