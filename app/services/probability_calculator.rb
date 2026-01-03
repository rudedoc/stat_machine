class ProbabilityCalculator
  def self.to_percentages(runners)
    # 1. Calculate raw implied probabilities safely
    raw_probs = runners.map do |r|
      back = r[:back_price].to_f # .to_f converts nil to 0.0
      lay  = r[:lay_price].to_f

      # Use mid-price if both exist, otherwise use whichever is available
      mid_price = if back > 0 && lay > 0
                    (back + lay) / 2.0
      elsif back > 0 || lay > 0
                    back > 0 ? back : lay
      else
                    0
      end

      # Avoid division by zero: if no price, probability is 0
      mid_price > 0 ? (1.0 / mid_price) : 0
    end

    # 2. Calculate the "Overround"
    total_book = raw_probs.sum

    # 3. Normalize to 100%
    runners.each_with_index.map do |runner, index|
      # If the whole market is suspended (total_book is 0), return 0%
      normalized_prob = total_book > 0 ? (raw_probs[index] / total_book) * 100 : 0

      {
        selection_id: runner[:selection_id],
        name: runner[:name],
        percentage: normalized_prob.round(1) # Rounding to 1 decimal for the tight UI
      }
    end
  end
end
