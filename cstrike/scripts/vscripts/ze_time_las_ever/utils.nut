/* --- Common functions --- */

/* --- Intended to have private scope (not called by entities) --- */

/** Shuffle an array using Fisher-Yates Algorithm; Shuffled in-place */
function _shuffleArray(arr) {
    local len = arr.len();
    // Start from the last element and swap with a random element before it
    for (local i = len - 1; i > 0; i--) {
        // Generate a random index from 0 to i (inclusive)
        local j = RandomInt(0, i);

        // Swap array[i] with array[j]
        local temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
}

/** Moves an element (matching value) to the front of an array, if present */
function _moveElementToFront(arr, val) {
    // Find the index of the value in the array
    local index = arr.find(val);

    // If find returns null, the element doesn't exist
    if (index != null) {
        // remove() returns the value at the given index
        // insert() puts it at the specified position (0 for front)
        arr.insert(0, arr.remove(index));
    }
    return arr;
}

/** Prints the elements of an array, space separated */
function _printlArray(arr) {
    foreach (index, value in arr) {
        print(value);
        // Print a space if it's not the last element
        if (index < arr.len() - 1) {
            print(" ");
        }
    }
    print("\n"); // Print the final newline
}

/**
 * Randomly selects up to 'count' non-consecutive numbers from the range [from, to]
 */
function _pickRandomNonConsecutive(from, to, count) {
    local selected = [];
    local invalid = {};

    local numbersPool = [];
    for (local i = from; i <= to; i++) { numbersPool.append(i); }
    _shuffleArray(numbersPool);

    foreach (num in numbersPool) {
        if (num in invalid) continue; // skip if number has been invalidated
        selected.append(num);

        // Mark the selected number, along its neighbours, as invalid
        invalid[num - 1] <- true;
        invalid[num] <- true;
        invalid[num + 1] <- true;

        if (selected.len() == count) break;
    }
    return selected;
}

/** Splits a string into an array of smaller text segments based on length and
/*  punctuation boundaries, preserving the words whole.
/*    - Attempts to stay between 40 and 80 characters.
/*    - Naturally prioritizes splitting at commas (,) or periods (.).
/*    - Will force split if the 80-character ceiling is reached */
function _breakTextIntoChunks(text) {
    local chunks = [];
    local words = split(text, " ");
    local currentChunk = "";

    foreach(word in words) { // Calculate what the chunk would be if we add this word
        local proposedChunk = (currentChunk == "") ? word : (currentChunk + " " + word);

        // If it exceeds the 80 character limit, finalize the current chunk and start a new one
        if (proposedChunk.len() > 80) {
            if (currentChunk.len() > 0) {
                chunks.append(currentChunk);
                currentChunk = word;
            }
        } else { // Update the chunk
            currentChunk = proposedChunk;

            // Check if it hit our minimum or a delimiter, and finalize it if safe
            if (currentChunk.len() >= 40) {
                local lastChar = currentChunk.slice(currentChunk.len() - 1);

                // If it ends with a comma/dot or the next word would push it over 80, we flush it
                if (lastChar == "," || lastChar == ".") {
                    chunks.append(currentChunk);
                    currentChunk = "";
                }
            }
        }
    }
    if (currentChunk.len() > 0) { // Add any remaining text
        chunks.append(currentChunk);
    }
    return chunks;
}

/* --- Facts --- */

/** Returns a random fact */
function _factRandom() {
    local randomIndex = RandomInt(0, facts.len() - 1);
    return facts[randomIndex];
}

if (!("facts" in this))
facts <- [ // list25.com/100-space-facts-speechless
"The Sun accounts for 99.8% of the total mass of our entire solar system. Everything else — every planet, moon, asteroid, and comet — makes up just the remaining 0.2%.",
"The Sun’s core temperature reaches approximately 15 million degrees Celsius (27 million °F). At its surface, temperatures “cool” to around 5,500°C (9,932°F).",
"Light leaving the Sun’s surface takes about 8 minutes and 20 seconds to reach Earth — but the energy that light carries took up to 100,000 years to travel from the core to the surface first.",
"Every second, the Sun converts roughly 4 million metric tons of matter into pure energy through nuclear fusion.",
"In approximately 5 billion years, the Sun will expand into a red giant, growing large enough to engulf Mercury and Venus — and possibly Earth.",
"The Sun is so large that approximately 1.3 million Earths could fit inside it.",
"Solar winds — streams of charged particles — travel from the Sun at speeds of 400 to 800 km/s (250–500 miles/s), reaching all the way to Pluto and beyond.",
"Despite being the closest planet to the Sun, Mercury is not the hottest. Its lack of atmosphere means temperatures swing from 430°C (806°F) during the day to -180°C (-292°F) at night.",
"Mercury is the smallest planet in the solar system — smaller than some moons, including Jupiter’s Ganymede.",
"A year on Mercury lasts just 88 Earth days, but a single Mercury day (one full rotation) takes 59 Earth days.",
"Venus is the hottest planet in the solar system, with an average surface temperature of 462°C (863°F) — hot enough to melt lead.",
"Venus rotates in the opposite direction to most planets. On Venus, the Sun rises in the west and sets in the east.",
"A day on Venus (243 Earth days) is actually longer than a year on Venus (225 Earth days). Time works differently there.",
"The atmospheric pressure on Venus is 92 times that of Earth — equivalent to being nearly 900 meters (3,000 feet) underwater.",
"Venus has more volcanoes than any other planet in the solar system, with over 1,600 major volcanoes identified on its surface.",
"Earth is the only planet in the known universe confirmed to host liquid water on its surface — and the only one confirmed to harbor life.",
"Earth’s Moon is gradually drifting away from our planet at a rate of approximately 3.8 cm (1.5 inches) per year. In the distant past, the Moon was much closer, causing colossal tides.",
"Earth’s Moon is the fifth-largest moon in the solar system, and it’s unusually large relative to its host planet.",
"The gravitational influence of the Moon stabilizes Earth’s axial tilt, which is why our planet has relatively stable seasons rather than chaotic climate swings.",
"Earth is not a perfect sphere — it bulges slightly at the equator due to its rotation, making it an oblate spheroid.",
"Mars gets its rusty red color from iron oxide (rust) covering much of its surface. The entire planet is essentially coated in a thin layer of rust.",
"Olympus Mons on Mars is the tallest volcano in the entire solar system, standing 21.9 km (13.6 miles) high — nearly three times the height of Mount Everest.",
"Mars has polar ice caps made of both water ice and frozen carbon dioxide (dry ice), which expand and contract with the Martian seasons.",
"Scientists have found strong evidence that Mars once had liquid water flowing on its surface billions of years ago, suggesting conditions that may have supported life.",
"Mars has two small moons — Phobos and Deimos — which are thought to be captured asteroids rather than formed alongside the planet.",
"Phobos is slowly spiraling toward Mars and is expected to crash into the planet (or break apart into a ring) in about 50 million years.",
"Jupiter is so massive that all the other planets in the solar system could fit inside it simultaneously — with room to spare.",
"Jupiter’s Great Red Spot is a storm that has been raging continuously for at least 350 years. It’s wider than the entire Earth, though it has been slowly shrinking.",
"Jupiter acts as a cosmic shield for Earth. Its massive gravity captures or deflects many comets and asteroids that would otherwise threaten the inner solar system.",
"Jupiter has at least 95 known moons. Its four largest — Io, Europa, Ganymede, and Callisto — were discovered by Galileo in 1610.",
"Europa, one of Jupiter’s moons, has a subsurface ocean of liquid water beneath its icy crust — and is considered one of the most promising places to search for extraterrestrial life in our solar system.",
"Jupiter’s moon Io is the most volcanically active body in the entire solar system, covered in hundreds of active volcanoes.",
"Saturn’s rings stretch up to 282,000 km (175,000 miles) in diameter but are remarkably thin — in some places, only about 10 meters (33 feet) thick.",
"Saturn’s rings are composed primarily of ice particles, rocky debris, and dust — ranging in size from tiny grains to chunks as large as houses.",
"Saturn is the least dense planet in the solar system. It’s less dense than water, meaning that if you could find an ocean big enough, Saturn would float.",
"Saturn’s moon Titan has a thick nitrogen atmosphere — the only moon in the solar system with a dense atmosphere — and features lakes and rivers of liquid methane.",
"A day on Saturn lasts only about 10.7 hours, even though the planet is massive. Its rapid rotation gives it a noticeably flattened shape at the poles.",
"Uranus rotates on its side, with an axial tilt of 97.77 degrees. Scientists believe a massive ancient collision knocked it into this unusual position.",
"Because of its extreme tilt, each pole of Uranus experiences 42 years of continuous sunlight followed by 42 years of complete darkness.",
"Uranus holds the record for the coldest planetary atmosphere in the solar system, reaching temperatures as low as -224°C (-371°F).",
"Uranus and Neptune are sometimes classified as “ice giants” rather than gas giants because they contain large amounts of water, methane, and ammonia in their interiors.",
"Neptune has the fastest winds of any planet in the solar system — clocking speeds of up to 2,100 km/h (1,300 mph), faster than the speed of sound on Earth.",
"Neptune was predicted mathematically before it was ever directly observed. Astronomers noticed irregularities in Uranus’s orbit and calculated that another planet must be pulling on it.",
"Neptune’s moon Triton orbits in the opposite direction of the planet’s rotation — a retrograde orbit suggesting it was captured from elsewhere, likely the Kuiper Belt.",
"Neptune’s Triton is the only large moon in the solar system with a retrograde orbit and also features cryovolcanoes — volcanoes that erupt nitrogen ice instead of lava.",
"Pluto was reclassified from a planet to a dwarf planet in 2006. It’s smaller than Earth’s Moon — a fact that still sparks fierce debate among space enthusiasts.",
"The asteroid belt between Mars and Jupiter contains millions of objects, but despite their numbers, the total mass of all asteroids combined is less than 4% of the Moon’s mass.",
"Ceres, the largest object in the asteroid belt between Mars and Jupiter, is classified as a dwarf planet. It contains roughly one-third of all the mass in the entire asteroid belt.",
"The Kuiper Belt extends from the orbit of Neptune out to about 50 AU (astronomical units) from the Sun, containing hundreds of thousands of icy bodies including Pluto.",
"Beyond the Kuiper Belt of Neptune lies the Oort Cloud — a vast, spherical shell of icy bodies that may extend up to 100,000 AU from the Sun, forming the true outer boundary of our solar system.",
"There are more stars in the observable universe than there are grains of sand on all of Earth’s beaches combined. The current estimate is around 10²⁴ stars (that’s 1 followed by 24 zeros).",
"The Milky Way alone contains an estimated 100 to 400 billion stars. Our Sun is just one of them — not particularly large, bright, or special in any cosmic sense.",
"Supernovae — the explosive deaths of massive stars — are so powerful they can briefly outshine an entire galaxy. They’re also responsible for forging and scattering many of the heavy elements in the universe.",
"Neutron stars are the densest objects in the universe short of black holes. A single teaspoon of neutron star material would weigh approximately 10 million tons on Earth.",
"Pulsars are rapidly rotating neutron stars that emit beams of electromagnetic radiation. Some rotate hundreds of times per second with extraordinary precision — so accurate they rival atomic clocks.",
"The largest known star, UY Scuti, is a hypergiant with a radius approximately 1,700 times that of the Sun. If placed at the center of our solar system, its surface would extend beyond the orbit of Jupiter.",
"Stars don’t actually twinkle. The twinkling effect (scintillation) is caused by Earth’s atmosphere. From space, stars appear as steady points of light.",
"White dwarfs — the remnants of stars like our Sun — are roughly the size of Earth but contain a mass comparable to the Sun. They cool slowly over billions of years.",
"The light you see when you look at a star is ancient. The star Betelgeuse, for example, is about 700 light-years away, meaning you’re seeing it as it looked 700 years ago.",
"Approximately 70% of stars in the Milky Way are red dwarfs — small, dim, and incredibly long-lived stars that burn hydrogen so slowly they can live for trillions of years.",
"Nothing — not even light — can escape a black hole once it crosses the event horizon, the point of no return.",
"At the center of virtually every large galaxy lies a supermassive black hole. The Milky Way’s central black hole, Sagittarius A*, has a mass of about 4 million suns.",
"Near a black hole, time dilation becomes extreme. An observer near the event horizon would experience time passing far more slowly than someone far away — this is a real, measurable effect predicted by Einstein’s general relativity.",
"The first-ever image of a black hole was captured in 2019 by the Event Horizon Telescope — the black hole at the center of galaxy M87, some 55 million light-years away.",
"If you fell into a black hole feet-first, the difference in gravitational pull between your feet and your head would stretch you like spaghetti — a process physicists actually call “spaghettification.”",
"Black holes don’t suck. They have gravity like any other massive object. If the Sun were magically replaced by a black hole of the same mass, Earth would continue orbiting normally — it just wouldn’t have any sunlight.",
"The Milky Way is a barred spiral galaxy estimated to be about 100,000 light-years across. Even at the speed of light, crossing it would take 100,000 years.",
"Our solar system is located in the Orion Arm, about 27,000 light-years from the galactic center — roughly halfway out from the center.",
"The Milky Way and the Andromeda galaxy are on a collision course. They’re expected to begin merging in about 4.5 billion years — though because galaxies are mostly empty space, stars are unlikely to collide directly.",
"The Milky Way completes one full rotation approximately every 225–250 million years. This is called a galactic year or cosmic year.",
"The Milky Way is not alone. It belongs to a cluster of galaxies called the Local Group, which also includes the Andromeda Galaxy and about 54 other smaller galaxies.",
"There are an estimated 2 trillion galaxies in the observable universe. That number was revised dramatically upward from a previous estimate of 200 billion in 2016.",
"The observable universe is approximately 93 billion light-years in diameter. “Observable” means the portion of the universe from which light has had time to reach us since the Big Bang.",
"Quasars are the most luminous objects in the universe — the intensely bright cores of distant galaxies powered by supermassive black holes devouring enormous amounts of matter.",
"Galaxies are not randomly scattered through space. They’re arranged in a cosmic web of filaments and voids, with galaxy clusters at the intersections — the largest known structures in the universe.",
"Nebulae are clouds of gas and dust where new stars are born. The Orion Nebula, visible to the naked eye, is a star-forming region just 1,344 light-years away.",
"Some nebulae are the remnants of dead stars — called planetary nebulae (despite having nothing to do with planets). They’re the beautiful, colorful shells of gas expelled by dying stars like our Sun will one day become.",
"The Pillars of Creation, a structure within the Eagle Nebula, are giant columns of gas and dust that stretch several light-years tall. They were famously photographed by Hubble in 1995 and again in stunning detail by the James Webb Space Telescope.",
"As of 2024, astronomers have confirmed over 5,600 exoplanets (planets orbiting stars other than our Sun). Thousands more await confirmation.",
"The TRAPPIST-1 system, 39 light-years away, contains seven Earth-sized planets — three of which sit in the habitable zone where liquid water could theoretically exist on the surface.",
"Some exoplanets have been discovered where it literally rains glass. HD 189733b has silicate particles in its atmosphere that condense and fall as glass shards, blown sideways at 8,700 km/h (5,400 mph).",
"Astronomers have discovered “hot Jupiters” — gas giant planets that orbit their stars in just a few days, closer than Mercury is to our Sun. Their existence initially baffled scientists and forced a rethink of planetary formation models.",
"The universe is approximately 13.8 billion years old, born from an inconceivably hot, dense singularity in an event known as the Big Bang.",
"The Cosmic Microwave Background (CMB) radiation is the afterglow of the Big Bang — faint microwave radiation detectable in every direction of the sky, the universe’s oldest “fossil light,” dating back about 380,000 years after the Big Bang.",
"In the first fraction of a second after the Big Bang, the universe underwent a period of exponential expansion called “inflation,” growing from subatomic size to macroscopic size almost instantaneously.",
"The universe is still expanding — and that expansion is accelerating. Distant galaxies are moving away from us faster and faster, meaning the universe will grow increasingly lonely and dark over cosmic timescales.",
"Only about 5% of the universe is made of ordinary matter — the atoms, molecules, and everything you can see, touch, or measure directly. The rest remains invisible to us.",
"Approximately 27% of the universe is dark matter — an invisible form of matter that doesn’t interact with light but exerts gravitational effects. We know it exists but have never directly detected it.",
"Approximately 68% of the universe is dark energy — a mysterious force driving the accelerating expansion of the universe. It’s the dominant component of the cosmos, and scientists still don’t know what it is.",
"Despite being invisible, dark matter’s presence is inferred from the way galaxies rotate (they spin too fast to be held together by visible matter alone) and from gravitational lensing effects.",
"A light-year is not a measure of time — it’s a measure of distance. One light-year equals approximately 9.46 trillion kilometers (5.88 trillion miles).",
"The speed of light is the cosmic speed limit: 299,792 km/s (186,282 miles/s) in a vacuum. No object with mass can reach or exceed this speed.",
"Time dilation is a real phenomenon. Astronauts aboard the International Space Station age very slightly slower than people on Earth — a difference confirmed by atomic clocks.",
"If you could travel at the speed of light to our nearest stellar neighbor, Proxima Centauri, it would take 4.24 years. At the speed of the fastest human-made spacecraft, it would take tens of thousands of years.",
"Atoms are mostly empty space. If an atom’s nucleus were the size of a marble, the atom itself would be roughly the size of a football stadium. By extension, all solid matter — including you — is overwhelmingly empty space.",
"Every atom in your body heavier than hydrogen was forged inside the core of an exploding star. Carbon, oxygen, nitrogen, iron — all of it. You are, quite literally, made of recycled stardust.",
"Hydrogen, which makes up most of your body’s water, was created in the minutes immediately following the Big Bang. The hydrogen atoms in your body are as old as the universe itself.",
"Gold and other heavy elements are thought to be created primarily in neutron star collisions — a cataclysmic event called a kilonova. Every piece of gold jewelry on Earth was forged in a cosmic catastrophe billions of years ago.",
"On April 12, 1961, Soviet cosmonaut Yuri Gagarin became the first human to travel to space, completing one orbit around Earth in 108 minutes aboard Vostok 1.",
"On July 20, 1969, Neil Armstrong became the first human to set foot on the Moon during NASA’s Apollo 11 mission. Buzz Aldrin joined him shortly after. The footprints they left in the lunar dust will likely remain for millions of years — the Moon has no wind or weather to erase them.",
"NASA’s Voyager 1 probe, launched in 1977, became the first human-made object to enter interstellar space in 2012. It carries a “Golden Record” — a time capsule of sounds, images, and greetings from Earth, intended for any intelligent life that might one day find it.",
"The International Space Station (ISS) orbits Earth every 90 minutes at approximately 28,000 km/h (17,500 mph). It’s been continuously inhabited since November 2, 2000.",
"The James Webb Space Telescope, launched in December 2021, can observe galaxies that formed just a few hundred million years after the Big Bang — giving humanity its clearest view yet of the universe’s earliest chapter. Its images have already revealed unexpected complexity in those ancient galaxies, forcing astronomers to rethink theories of galaxy formation.",
"Astronauts grow up to 3 centimeters (about 1.2 inches) taller in space. Without gravity compressing the spine, the discs between vertebrae expand. They return to normal height shortly after returning to Earth.",
"NASA’s Perseverance rover has been collecting rock samples on Mars since 2021, searching for signs of ancient microbial life. It represents the most sophisticated Mars mission in history and is part of a long-term plan to eventually return those samples to Earth."
]