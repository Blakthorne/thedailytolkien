class QuoteInteractionChannel < ApplicationCable::Channel
  def subscribed
    quote = Quote.find(params[:quote_id])
    stream_for quote

    Rails.logger.info "User subscribed to quote interactions for quote #{quote.id}"
  end

  def unsubscribed
    Rails.logger.info "User unsubscribed from quote interactions"
  end
end
