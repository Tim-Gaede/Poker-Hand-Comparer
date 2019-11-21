using Parameters
using Combinatorics
using OffsetArrays
using Formatting


@with_kw struct Card #: IComparable
    rank::Int64
    suit::Char
end

@with_kw mutable struct Hand
    cards::Array{Card,1}
    ordered_by_card_rank::Bool = false # lowest to highest
    sorted_for_poker::Bool = false # left-to-right evaluation
    tier = nothing
end



function tierName(tier::Int64)
    if tier == 0;    return "Garbage";   end
    if tier == 1;    return "Pair";    end
    if tier == 2;    return "Two Pair";    end
    if tier == 3;    return "Three-of-a-Kind";    end
    if tier == 4;    return "Straight";    end
    if tier == 5;    return "Flush";    end
    if tier == 6;    return "Full House";    end
    if tier == 7;    return "Four-of-a-Kind";    end
    if tier == 8;    return "Straight Flush";    end

    return "Unknown tier"
end


function sortComparable!(a::Array, compareTo)

    #inertionSort for comparable
    function insSort_comp!(a::Array, compareTo)

        for i = 2 : length(a)
            j = i
            while j > 1  &&  compareTo(a[j], a[j-1]) < 0
                a[j], a[j-1]  =  a[j-1], a[j] # swap
                j -= 1
            end
        end

    end

    #quickSort for comparable
    function qSort_comp!(a::Array, lo::Int64, hi::Int64, compareTo)

        i = lo;  j = hi
        while i < hi
            pivot = a[(lo+hi) ÷ 2]
            while i <= j
                while compareTo(a[i], pivot) < 0;    i += 1;    end
                while compareTo(a[j], pivot) > 0;    j -= 1;    end
                if i <= j
                    a[i], a[j]  =  a[j], a[i] # swap
                    i += 1;  j -= 1
                end
            end
            if lo < j;     qSort_comp!(a, lo, j, compareTo);    end
            lo = i;  j = hi
        end

    end


    if length(a) ≤ 60
        insSort_comp!(a, compareTo)
    else
        qSort_comp!(a, 1, length(a), compareTo)
    end

end

function compareTo(hand₁::Hand,  hand₂::Hand)

    if hand₁.tier > hand₂.tier;    return  1;    end
    if hand₁.tier < hand₂.tier;    return -1;    end

    if !hand₁.sorted_for_poker;    sortForPoker!(hand₁);    end
    if !hand₂.sorted_for_poker;    sortForPoker!(hand₂);    end


    if hand₁.tier == 8  ||  hand₁.tier == 4 # Straight Flush or Straight
        # We only need compare one card from each hand.
        # Might as well be the first cards
        if hand₁.cards[1].rank > hand₂.cards[1].rank;    return  1;    end
        if hand₁.cards[1].rank < hand₂.cards[1].rank;    return -1;    end

        return 0

    elseif hand₁.tier == 7 # Four-of-a-kind
        # First, compare the quartets
        if hand₁.cards[1].rank > hand₂.cards[1].rank;    return  1;    end
        if hand₁.cards[1].rank < hand₂.cards[1].rank;    return -1;    end

        # Both hands may have the same Four-of-a-Kind from
        # two or more decks shuffled together

        # Next, compare the remainder cards
        if hand₁.cards[5].rank > hand₂.cards[5].rank;    return  1;    end
        if hand₁.cards[5].rank < hand₂.cards[5].rank;    return -1;    end

        return 0

    elseif hand₁.tier == 6 # Full House
        # First, compare the trios
        if hand₁.cards[1].rank > hand₂.cards[1].rank;    return  1;    end
        if hand₁.cards[1].rank < hand₂.cards[1].rank;    return -1;    end

        # Both hands may have the same Full House from
        # two or more decks shuffled together

        # Next, compare the duos
        if hand₁.cards[5].rank > hand₂.cards[5].rank;    return  1;    end
        if hand₁.cards[5].rank < hand₂.cards[5].rank;    return -1;    end

        return 0


    elseif hand₁.tier == 5  ||  hand₁.tier == 0 # Flush or Garbage
        # Simply compare the cards in sequence left-to-right until
        # one card outranks the other
        if hand₁.cards[1].rank > hand₂.cards[1].rank;    return  1;    end
        if hand₁.cards[1].rank < hand₂.cards[1].rank;    return -1;    end

        if hand₁.cards[2].rank > hand₂.cards[2].rank;    return  1;    end
        if hand₁.cards[2].rank < hand₂.cards[2].rank;    return -1;    end

        if hand₁.cards[3].rank > hand₂.cards[3].rank;    return  1;    end
        if hand₁.cards[3].rank < hand₂.cards[3].rank;    return -1;    end

        if hand₁.cards[4].rank > hand₂.cards[4].rank;    return  1;    end
        if hand₁.cards[4].rank < hand₂.cards[4].rank;    return -1;    end

        if hand₁.cards[5].rank > hand₂.cards[5].rank;    return  1;    end
        if hand₁.cards[5].rank < hand₂.cards[5].rank;    return -1;    end

        return 0

    elseif hand₁.tier == 3 # Three-of-a-Kind
        # First, compare the trios
        if hand₁.cards[1].rank > hand₂.cards[1].rank;    return  1;    end
        if hand₁.cards[1].rank < hand₂.cards[1].rank;    return -1;    end

        # Then compare the 4ᵗʰ cards
        if hand₁.cards[4].rank > hand₂.cards[4].rank;    return  1;    end
        if hand₁.cards[4].rank < hand₂.cards[4].rank;    return -1;    end

        # Finally, the 5ᵗʰ cards
        if hand₁.cards[5].rank > hand₂.cards[5].rank;    return  1;    end
        if hand₁.cards[5].rank < hand₂.cards[5].rank;    return -1;    end

        return 0

    elseif hand₁.tier == 2 # Two Pair
        # First, compare the higher ranked pairs
        if hand₁.cards[1].rank > hand₂.cards[1].rank;    return  1;    end
        if hand₁.cards[1].rank < hand₂.cards[1].rank;    return -1;    end

        # Then compare the lower ranked pairs
        if hand₁.cards[3].rank > hand₂.cards[3].rank;    return  1;    end
        if hand₁.cards[3].rank < hand₂.cards[3].rank;    return -1;    end

        # Finally, the 5ᵗʰ cards
        if hand₁.cards[5].rank > hand₂.cards[5].rank;    return  1;    end
        if hand₁.cards[5].rank < hand₂.cards[5].rank;    return -1;    end

        return 0

    elseif hand₁.tier == 1 # Pair
        # First, compare the pairs
        if hand₁.cards[1].rank > hand₂.cards[1].rank;    return  1;    end
        if hand₁.cards[1].rank < hand₂.cards[1].rank;    return -1;    end

        # Then compare the 3ʳᵈ cards
        if hand₁.cards[3].rank > hand₂.cards[3].rank;    return  1;    end
        if hand₁.cards[3].rank < hand₂.cards[3].rank;    return -1;    end

        # Then compare the 4ᵗʰ cards
        if hand₁.cards[4].rank > hand₂.cards[4].rank;    return  1;    end
        if hand₁.cards[4].rank < hand₂.cards[4].rank;    return -1;    end

        # Finally, the 5ᵗʰ cards
        if hand₁.cards[5].rank > hand₂.cards[5].rank;    return  1;    end
        if hand₁.cards[5].rank < hand₂.cards[5].rank;    return -1;    end

        return 0

    end



end



#swap(a, b) = (a,b = b,a)
function swapCards!(hand::Hand, i₁, i₂)
    hand.cards[i₁], hand.cards[i₂] = hand.cards[i₂], hand.cards[i₁]
end




function compareTo(card_1ˢᵗ::Card,  card_2ⁿᵈ::Card)
    if card_1ˢᵗ.rank > card_2ⁿᵈ.rank;    return  1;    end
    if card_1ˢᵗ.rank < card_2ⁿᵈ.rank;    return -1;    end
    return 0
end

function order!(hand::Hand)
    sortComparable!(hand.cards, compareTo)
    hand.ordered_by_card_rank = true
end




function setTier!(hand::Hand) # May rearrange the hand, hence the bang
    if !hand.ordered_by_card_rank;    order!(hand);    end


    ranks_ordered = ranksOrdered(hand)
    suits_same = suitsSame(hand)


    if ranks_ordered  &&  suits_same
        hand.tier = 8 # Straight Flush (including Royal Flush)
    elseif is4Kind(hand)
        hand.tier = 7 # Four-of-a-kind
    elseif isFullHouse(hand)
        hand.tier = 6 # Full House
    elseif suits_same
        hand.tier = 5 # Flush
    elseif ranks_ordered
        hand.tier = 4 # Straight
    elseif is3Kind(hand)
        hand.tier = 3 # Three-of-a-kind
    elseif is2Pair(hand)
        hand.tier = 2 # Two-Pair
    elseif isPair(hand)
        hand.tier = 1 # Pair
    else
        hand.tier = 0 # Garbage
    end
end



function sortForPoker!(hand::Hand)
# For left-to-right evaluation
    if hand.tier == nothing;    setTier!(hand);    end

    if hand.sorted_for_poker
        msg = "Instance of struct Hand already sorted for poker.\n\n" *
              "Check the field, \".sorted_for_poker\" BEFORE " *
              "attempting a sort."
        throw(Exception(msg))
    end

    reverse!(hand.cards)

    if hand.tier == 8  ||  hand.tier == 4 # Straight Flush or Straight
        if hand.cards[1].rank == 14  &&  hand.cards[5].rank == 2
            swapCards!(hand, 1, 2) # Ace is equivalent to a 1
            swapCards!(hand, 2, 3)
            swapCards!(hand, 3, 4)
            swapCards!(hand, 4, 5)
        end

    elseif hand.tier == 7 # Four-of-a-Kind
        if hand.cards[1].rank !== hand.cards[2].rank
            swapCards!(hand, 1, 5)
        end
    elseif hand.tier == 6 # Full House
        if hand.cards[2].rank !== hand.cards[3].rank
            reverse!(hand.cards)
        end
    elseif hand.tier == 3 # Three-of-a-kind
        if hand.cards[2].rank == hand.cards[4].rank
            swapCards!(hand, 1, 4)
        elseif hand.cards[3].rank == hand.cards[5].rank
            swapCards!(hand, 1, 4)
            swapCards!(hand, 2, 5)
        end
    elseif hand.tier == 2 # Two Pair
        if hand.cards[2].rank == hand.cards[3].rank  &&
           hand.cards[4].rank == hand.cards[5].rank
            swapCards!(hand, 1, 3)
            swapCards!(hand, 3, 5)
        elseif hand.cards[1].rank == hand.cards[2].rank  &&
               hand.cards[4].rank == hand.cards[5].rank
            swapCards!(hand, 3, 5)
        end

    else # hand.tier == 1 # Pair
        if hand.cards[4].rank == hand.cards[5].rank
            swapCards!(hand, 1, 3)
            swapCards!(hand, 2, 4)
            swapCards!(hand, 1, 5)
        elseif hand.cards[3].rank == hand.cards[4].rank
            swapCards!(hand, 1, 3)
            swapCards!(hand, 2, 4)
        elseif hand.cards[2].rank == hand.cards[3].rank
            swapCards!(hand, 1, 3)
        end
    end

    hand.ordered_by_card_rank = false
    hand.sorted_for_poker = true
end



function ranksOrdered(hand::Hand)
    if !hand.ordered_by_card_rank;    order!(hand);    end


    if hand.cards[5].rank == 14  && # Ace
       hand.cards[4].rank ==  5  &&
       hand.cards[3].rank ==  4  &&
       hand.cards[2].rank ==  3  &&
       hand.cards[1].rank ==  2

       return true
    end


    if hand.cards[5].rank - hand.cards[4].rank == 1  &&
       hand.cards[4].rank - hand.cards[3].rank == 1  &&
       hand.cards[3].rank - hand.cards[2].rank == 1  &&
       hand.cards[2].rank - hand.cards[1].rank == 1

       return true
    end

    return false
end



function suitsSame(hand::Hand)

   if hand.cards[1].suit == hand.cards[2].suit  &&
      hand.cards[2].suit == hand.cards[3].suit  &&
      hand.cards[3].suit == hand.cards[4].suit  &&
      hand.cards[4].suit == hand.cards[5].suit

      return true
   end

   return false
end

function is4Kind(hand::Hand)
# Assumes cards are already ordered and previous tests made for higher tiers

    if hand.cards[1].rank == hand.cards[2].rank  &&
       hand.cards[2].rank == hand.cards[3].rank  &&
       hand.cards[3].rank == hand.cards[4].rank

       return true
    end


    if hand.cards[2].rank == hand.cards[3].rank  &&
       hand.cards[3].rank == hand.cards[4].rank  &&
       hand.cards[4].rank == hand.cards[5].rank

       return true
    end

    return false
end

function isFullHouse(hand::Hand)
# Assumes cards are already ordered and previous tests made for higher tiers

    if hand.cards[1].rank == hand.cards[2].rank  &&
       hand.cards[3].rank == hand.cards[4].rank ==  hand.cards[5].rank

       return true
    end

    if hand.cards[1].rank == hand.cards[2].rank == hand.cards[3].rank &&
       hand.cards[4].rank == hand.cards[5].rank

       return true
    end

    return false
end


function is3Kind(hand::Hand)
# Assumes cards are already ordered and previous tests made for higher tiers

    if hand.cards[1].rank == hand.cards[2].rank  == hand.cards[3].rank
       return true
    end

    if hand.cards[2].rank == hand.cards[3].rank  == hand.cards[4].rank
       return true
    end

    if hand.cards[3].rank == hand.cards[4].rank  == hand.cards[5].rank
       return true
    end

    return false
end


function is2Pair(hand::Hand)
# Assumes cards are already ordered and previous tests made for higher tiers

    if hand.cards[1].rank == hand.cards[2].rank
        if hand.cards[3].rank == hand.cards[4].rank
            return true
        end

        if hand.cards[4].rank == hand.cards[5].rank
            return true
        end
    elseif hand.cards[2].rank == hand.cards[3].rank &&
           hand.cards[4].rank == hand.cards[5].rank

        return true
    end


    return false
end

function isPair(hand::Hand)
# Assumes cards are already ordered and previous tests made for higher tiers

    if hand.cards[1].rank == hand.cards[2].rank  ||
       hand.cards[2].rank == hand.cards[3].rank  ||
       hand.cards[3].rank == hand.cards[4].rank  ||
       hand.cards[4].rank == hand.cards[5].rank

        return true
    end


    return false
end



function str(card::Card)
    if card.rank == 14;    ans = "A"
    elseif card.rank in range(2, stop=9);  ans = string(card.rank)
    elseif card.rank == 10;    ans = "T"
    elseif card.rank == 11;    ans = "J"
    elseif card.rank == 12;    ans = "Q"
    elseif card.rank == 13;    ans = "K"
    end

    ans *= card.suit
end



function profile(hand::Hand)
    output = str(hand) * "\n"

    if hand.ordered_by_card_rank
        output *= "Ordered by card rank\n"
    elseif hand.sorted_for_poker
        output *= "Sorted for poker\n"
    else
        output *= "Not ordered\n"
    end
    output *= tierName(hand.iter)
    output *= "\n"

    output
end




function str(hand::Hand)

    res = ""
    for i = 1 : length(hand.cards) - 1
        res *= str(hand.cards[i]) * " "
    end
    res *= str(last(hand.cards))

    res
end


function card_by_code(code_1_to_52::Int64)

    code_0_to_51 = code_1_to_52 - 1

    if     code_0_to_51 % 4 == 0;    suit = '♣'
    elseif code_0_to_51 % 4 == 1;    suit = '♦'
    elseif code_0_to_51 % 4 == 2;    suit = '♥'
    else                             suit = '♠'
    end

    Card(code_0_to_51 ÷ 4 + 2, suit)
end




function randSubarr(arr::Array, len::Int64)
    if len == length(arr);    return arr;    end

    ans = []
    indices_chosen = []

    while length(indices_chosen) < len
        i = rand(1 :  length(arr))

        if i ∉ indices_chosen
            push!(ans, arr[i])
            push!(indices_chosen, i)
        end
    end

    ans
end

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function main()
    println("\n"^2, "-"^60, "\n"^3)



    deck = [card_by_code(n)   for n = 1 : 52]

    combis = combinations(deck, 5)

    tierCnts = OffsetVector{Int64}(undef, 0:8)
    for i = 0 : 8;    tierCnts[i] = 0;    end


    hands = []
    for combi in combis
        hand = Hand(cards = combi)
        sortForPoker!(hand)
        push!(hands, hand)
        tierCnts[hand.tier] += 1
    end

    println("    Combinations:")
    PADr = 15
    PADl =  9
    for i = 8 : -1 : 0
        name = rpad(tierName(i), PADr)
        count = lpad(format(tierCnts[i], commas=true), PADl)
        println(name, count)
    end
    fmd = lpad(format(length(combis), commas=true), PADl)
    println(rpad("Total", PADr), fmd)
    println("\n"^6)

    sortComparable!(hands, compareTo)


    distinctions = OffsetVector{Int64}(undef, 0:8)
    for i = 0:8
        distinctions[i] = 1
    end

    for i = 1 : length(hands) - 1
        if compareTo(hands[i], hands[i+1]) !== 0  &&
           hands[i].tier == hands[i+1].tier

            distinctions[hands[i].tier] += 1
        end
    end

    PADl₂ = 5
    println("    Hand ranks:")
    for i = 8 : -1 : 0
        name = rpad(tierName(i), PADr)
        count = lpad(format(distinctions[i], commas=true), PADl₂)
        println(name, count)
    end
    fmd = lpad(format(sum(distinctions), commas=true), PADl₂)
    println(rpad("Total", PADr), fmd)


end
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
main()
