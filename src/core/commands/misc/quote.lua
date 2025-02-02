local cmd = {
	name = script.Name,
	desc = [[Displays a random motivational quote]],
	usage = [[$ quote]],
	fn = function(plr, pCsi, essentials, args)
		local quotes = {
			'"Every man has his secret sorrows which the world knows not; and often times we call a man cold when he is only sad." -Henry Wadsworth Longfellow';
			'"I came, I saw, I conquered." - Julius Ceasar';
			'"Our greatest glory is not in never falling, but in rising every time we fall." - Confucius';
			'"History will be kind for me for I intend to write it." - Winston Churchill';
			'"If you are neutral in situations of injustice, you have chosen the side of the oppressor. If an elephant has its foot on the tail of a mouse and you say that you are neutral, the mouse will not appreciate your neutrality." - Desmond Tutu';
			'"History is a relentless master. It has no present, only the past rushing into the future. To try to hold fast is to be swept aside." - John F. Kennedy';
			'"Those who do not remember the past are condemned to repeat it." - George Santayana';
			'"A pint of sweat, saves a gallon of blood." - George S. Patton';
			'"This is one small step for a man, one giant leap for mankind." - Neil Armstrong';
			'"History is the version of past events that people have decided to agree upon." - Napoleon Bonaparte';
			'"To see the world, things dangerous to come to, to see behind walls, to draw closer, to find each other and to feel. That is the purpose of life." - Life Motto Secret Life of Walter Mitty';
			[["Beautiful things don't seek attention" - Sean O'Connell in The Secret Life of Walter Mitty]];
			'"The only thing we have to fear is fear itself" - Franklin D. Roosevelt';
			'"Do what you can, with what you have, where you are." - Theodore Roosevelt';
			'"Even if I knew that tomorrow the world would go to pieces, I would still plant my apple tree." - Martin Luther';
			'"Thousands of candles can be lighted from a single candle, and the life of the candle will not be shortened. Happiness never decreases by being shared." - Buddha';
			[["We can't help everyone, but everyone and help someone." - Ronald Reagan]];
			'"Our greatest weakness lies in giving up. The most certain way to succeed is always to try just one more time." - Thomas A. Edison';
			[["Even if you fall on your face, you're still moving forward." - Victor Kiam]];
			'"Strive not to be a success, but rather to be of value." - Albert Einstein';
			[["You miss 100% of the shots you don't take." - Wayne Gretzky]];
			[["Your time is limited, so don't waste it living someone else's life." - Steve Jobs]];
			'"The only person you are destined to become is the person you decide to be." - Ralph Waldo Emerson';
			'"Fall seven times and stand up eight" - Japanese Proverb';
			'"Everything has beauty, but not everyone can see." - Confucius';
			'"A person who never made a mistake never tried anything new." - Albert Einstein';
			'"The person who says it cannot be done should not interrupt the person who is doing it." - Chinese Proverb';
			'"It does not matter how slowly you go as long as you do not stop." - Confucius';
			'"Everything you see exists together in a delicate balance. As king, you need to understand that balance and respect all the creatures, from the crawling ant to the leaping antelope. " - Mufasa to Simba in The Lion King';
			'"Hakuna Matata - It means no worrys for the rest of your days." - The Lion King';
			'"You must take your place in the Circle of Life." - Mufasa to Simba in The Lion King';
			'"The journey of a thousand miles begins with one step." - Lao Tzu';
			'"I\'ll be with you... even if you can\'t see me." - Little Foot\'s Mother in Land Before Time';
			'"You were worth it, old friend, and a thousand times over." - Where the red fern grows.';
		}
		local quote = quotes[math.random(1,#quotes)]
		essentials.Console.info("Quote of the day: "..quote)
	end,
}

return cmd
