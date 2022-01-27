import Random
import Wordlebot

num_guesses = parse(Int16, ARGS[1])
num_targets = parse(Int16, ARGS[2])

guesses, targets = Wordlebot.Wordlist.load()
test_guesses = Random.shuffle(guesses)[1:num_guesses]
test_targets = Random.shuffle(targets)[1:num_targets]
@time for guess in test_guesses, target in test_targets
    Wordlebot.cluefor(guess, target)
end
