class PushReceiptPollJob < ApplicationJob
  queue_as :default

  MAX_ATTEMPTS = 3
  RETRY_DELAY = 60.seconds

  def perform(ticket_ids, attempt = 1)
    ticket_ids = Array(ticket_ids).compact
    return if ticket_ids.empty?

    receipts = PushSender.fetch_receipts(ticket_ids)
    pending = []

    ticket_ids.each do |ticket_id|
      receipt = receipts[ticket_id]

      if receipt.nil?
        pending << ticket_id
        next
      end

      process_receipt(ticket_id, receipt)
    end

    if pending.any?
      return self.class.set(wait: RETRY_DELAY).perform_later(pending, attempt + 1) if attempt < MAX_ATTEMPTS

      pending.each { |ticket_id| cleanup_ticket(ticket_id) }
    end
  end

  private

  def process_receipt(ticket_id, receipt)
    return cleanup_ticket(ticket_id) if receipt["status"] == "ok"

    details = receipt["details"] || {}
    if details["error"] == "DeviceNotRegistered"
      deactivate_mapped_device_token(ticket_id)
    else
      Rails.logger.warn("Push receipt error for ticket #{ticket_id}: #{receipt.inspect}")
      cleanup_ticket(ticket_id)
    end
  end

  def deactivate_mapped_device_token(ticket_id)
    push_ticket = PushTicket.includes(:device_token).find_by(ticket_id: ticket_id)

    if push_ticket&.device_token
      push_ticket.device_token.deactivate!
      push_ticket.destroy!
    else
      Rails.logger.warn("Push receipt DeviceNotRegistered for unmapped ticket #{ticket_id}")
    end
  end

  def cleanup_ticket(ticket_id)
    PushTicket.where(ticket_id: ticket_id).delete_all
  end
end
