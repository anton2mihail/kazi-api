module Api
  module V1
    class ReferenceController < ApplicationController
      TRADES = [
        "General Labourer",
        "Carpenter",
        "Electrician (Licensed)",
        "Electrician (Apprentice)",
        "Plumber (Licensed)",
        "Plumber (Apprentice)",
        "HVAC Technician",
        "Welder",
        "Roofer",
        "Concrete Finisher",
        "Heavy Equipment Operator",
        "Painter",
        "Drywall Installer",
        "Landscaper"
      ].freeze

      LOCATIONS = [
        "Toronto - Central",
        "Toronto - East",
        "Toronto - West",
        "Toronto - North",
        "Mississauga",
        "Brampton",
        "Markham",
        "Vaughan",
        "Hamilton",
        "Kitchener",
        "Waterloo",
        "London",
        "Ottawa"
      ].freeze

      def trades
        render_success(TRADES)
      end

      def locations
        render_success(LOCATIONS)
      end
    end
  end
end
