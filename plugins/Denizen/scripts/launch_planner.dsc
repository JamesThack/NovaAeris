# NovaAeris launch planner for Galactifun rockets.
#
# /planets                    opens the solar system map (remembers each player's fuel and amount)
# /planets <fuel> [amount]    prints the same information in chat
# Aliases: /launchplanner, /launchwindows
#
# Galactifun 2.0.2.10 moves planets with the real clock, so this recreates its maths exactly:
#   orbit angle    = (current millis % year) * 2 * PI / year
#   year (millis)  = int(35 * earth years) * 1,200,000
#   planet to planet distance = law of cosines on both orbits around the Sun
#   moon distance  = moon orbit radius + distance to its planet
#   reach          = fuel items * fuel efficiency * 2,000,000 km
# If Galactifun is updated, re-check these numbers against the new version.
#
# Reload after editing with: /ex reload

launch_planner_data:
  type: data
  km_per_fuel: 2000000
  max_amount: 500
  # fuel id: efficiency / icon / display name
  fuels:
    fuel_bucket: 1/lava_bucket/Fuel Bucket
    oil: 0.5/ink_sac/Oil Bucket
    hydrogen: 3.5/light_blue_dye/Hydrogen
    ammonia: 4/lime_dye/Ammonia
    methane: 6/orange_dye/Methane
    argon: 18/purple_dye/Argon (ion rocket)
  fuel_order:
  - fuel_bucket
  - oil
  - hydrogen
  - ammonia
  - methane
  - argon
  # orbit radius in km / orbital period in real milliseconds
  bodies:
    earth: 149600000/42000000
    venus: 108860000/25200000
    mars: 227943824/78000000
    jupiter: 778340821/504000000
    saturn: 1490500000/1218000000
  # Rocket destinations: display name / body it orbits or is / extra km from that body / icon
  targets:
  - Earth Orbit/earth/24000/daylight_detector
  - The Moon/earth/382500/end_stone
  - Venus/venus/0/magma_block
  - Mars/mars/0/red_sand
  - Io/jupiter/421800/yellow_terracotta
  - Titan/saturn/1200000/orange_terracotta
  - Enceladus/saturn/237948/packed_ice
  # Map planets, drawn outer to inner so inner planets win a crowded cell:
  # body / ring width / ring height / icon / name / moons shown beside it (comma separated)
  map_planets:
  - saturn/4/2/yellow_glazed_terracotta/Saturn/Titan,Enceladus
  - jupiter/4/2/orange_glazed_terracotta/Jupiter/Io
  - mars/3/2/red_sand/Mars/
  - earth/2/1/grass_block/Earth/The Moon,Earth Orbit
  - venus/1/1/magma_block/Venus/
  # Background stars on the map
  stars: 2|7|10|17|20|26|29|34|38|42

# ---------------------------------------------------------------- maths

# Fuel needed (in fuel buckets) to reach a target from Earth at a given time in millis.
launch_planner_need:
  type: procedure
  debug: false
  definitions: target|time
  script:
  - define parts <[target].split[/]>
  - define body <[parts].get[2]>
  - define offset <[parts].get[3]>
  - define km_per_fuel <script[launch_planner_data].data_key[km_per_fuel]>
  - if <[body]> == earth:
    - determine <[offset].div[<[km_per_fuel]>]>
  - define earth <script[launch_planner_data].data_key[bodies.earth].split[/]>
  - define planet <script[launch_planner_data].data_key[bodies.<[body]>].split[/]>
  - define re <[earth].get[1]>
  - define rp <[planet].get[1]>
  - define angle_e <[time].mod[<[earth].get[2]>].mul[<util.pi>].mul[2].div[<[earth].get[2]>]>
  - define angle_p <[time].mod[<[planet].get[2]>].mul[<util.pi>].mul[2].div[<[planet].get[2]>]>
  - define cross <[re].mul[<[rp]>].mul[2].mul[<[angle_e].sub[<[angle_p]>].cos>]>
  - define km <[re].power[2].add[<[rp].power[2]>].sub[<[cross]>].sqrt.add[<[offset]>]>
  - determine <[km].div[<[km_per_fuel]>]>

# Closest a target can ever get, in fuel buckets.
launch_planner_best:
  type: procedure
  debug: false
  definitions: target
  script:
  - define parts <[target].split[/]>
  - define body <[parts].get[2]>
  - define km_per_fuel <script[launch_planner_data].data_key[km_per_fuel]>
  - if <[body]> == earth:
    - determine <[parts].get[3].div[<[km_per_fuel]>]>
  - define re <script[launch_planner_data].data_key[bodies.earth].split[/].get[1]>
  - define rp <script[launch_planner_data].data_key[bodies.<[body]>].split[/].get[1]>
  - determine <[rp].sub[<[re]>].abs.add[<[parts].get[3]>].div[<[km_per_fuel]>]>

# Whether a target is in range for a reach (in fuel buckets). Returns a map with
# need, best, state (now/later/never/none) and minutes:
#   now   = in range; minutes = how long it stays in range (-1 = always, 0 = over 36 hours)
#   later = comes into range in <minutes>
#   never = out of reach even at its closest
#   none  = not in range within 36 hours
# Every planet comes back round within about 26 hours, so it searches 36 hours in 15 minute steps.
launch_planner_status:
  type: procedure
  debug: false
  definitions: target|range|now
  script:
  - define need <proc[launch_planner_need].context[<[target]>|<[now]>]>
  - define best <proc[launch_planner_best].context[<[target]>]>
  - define info <map.with[need].as[<[need]>].with[best].as[<[best]>]>
  - if <[need]> <= <[range]>:
    - if <[target].split[/].get[2]> == earth:
      - determine <[info].with[state].as[now].with[minutes].as[-1]>
    - repeat 144 as:step:
      - if <proc[launch_planner_need].context[<[target]>|<[now].add[<[step].mul[900000]>]>]> > <[range]>:
        - determine <[info].with[state].as[now].with[minutes].as[<[step].mul[15]>]>
    - determine <[info].with[state].as[now].with[minutes].as[0]>
  - if <[best]> > <[range]>:
    - determine <[info].with[state].as[never].with[minutes].as[0]>
  - repeat 144 as:step:
    - if <proc[launch_planner_need].context[<[target]>|<[now].add[<[step].mul[900000]>]>]> <= <[range]>:
      - determine <[info].with[state].as[later].with[minutes].as[<[step].mul[15]>]>
  - determine <[info].with[state].as[none].with[minutes].as[0]>

# One coloured status line from the values in a status map.
launch_planner_status_text:
  type: procedure
  debug: false
  definitions: state|minutes|best|eff
  script:
  - choose <[state]>:
    - case now:
      - if <[minutes]> == -1:
        - determine "<green>✔ In range now (always)"
      - if <[minutes]> == 0:
        - determine "<green>✔ In range now, for over 36 hours"
      - determine "<green>✔ In range now, for about <duration[<[minutes]>m].formatted>"
    - case later:
      - define when <util.time_now.to_utc.add[<[minutes]>m].format[EEE HH:mm]>
      - determine "<yellow>● In range in about <duration[<[minutes]>m].formatted> <gray>(<[when]> GMT)"
    - case never:
      - determine "<red>✖ Out of reach<&co> needs at least <[best].div[<[eff]>].round_up> even at its closest"
    - default:
      - determine "<red>✖ Not in range in the next 36 hours"

# ---------------------------------------------------------------- GUI

launch_planner_gui:
  type: inventory
  inventory: chest
  title: <&8>✦ Solar System <&7>· <&8>Launch Planner
  size: 54
  gui: true

# Finds a free map cell at or next to <[x]>,<[y]> (0-8, 0-4) that is not in <[used]>.
# Sets <[slot]> (or null) and adds it to <[used]>. Inject only.
launch_planner_place:
  type: task
  debug: false
  script:
  - define slot null
  - foreach <list[0,0|1,0|-1,0|0,1|0,-1|1,1|-1,1|1,-1|-1,-1|2,0|-2,0|2,1|-2,1|2,-1|-2,-1]> as:offset:
    - define cx <[x].add[<[offset].before[,]>]>
    - define cy <[y].add[<[offset].after[,]>]>
    - if <[cx]> < 0 || <[cx]> > 8 || <[cy]> < 0 || <[cy]> > 4:
      - foreach next
    - define candidate <[cy].mul[9].add[<[cx]>].add[1]>
    - if <[used].contains[<[candidate]>]>:
      - foreach next
    - define slot <[candidate]>
    - define used:->:<[candidate]>
    - foreach stop

# Sets <[target]> to the targets entry whose name is <[find]>. Inject only.
# (A plain loop: ListTag.filter can't see this queue's definitions.)
launch_planner_find:
  type: task
  debug: false
  script:
  - define target null
  - foreach <script[launch_planner_data].data_key[targets]> as:candidate:
    - if <[candidate].split[/].first> == <[find]>:
      - define target <[candidate]>
      - foreach stop

# Works out status, colour and lore for one destination. Expects <[target]>. Inject only.
launch_planner_dest:
  type: task
  debug: false
  script:
  - if <[target]> == null:
    - define color <gray>
    - define need 0
    - define dest_lore <list[<gray>No data for this destination.]>
  - else:
    - define info <proc[launch_planner_status].context[<[target]>|<[range]>|<[now]>]>
    - define need <[info].get[need]>
    - define status <proc[launch_planner_status_text].context[<[info].get[state]>|<[info].get[minutes]>|<[info].get[best]>|<[eff]>]>
    - choose <[info].get[state]>:
      - case now:
        - define color <green>
      - case later:
        - define color <yellow>
      - default:
        - define color <red>
    - define dest_lore <list>
    - define "dest_lore:->:<gray>Distance from Earth<&co> <white><[need].mul[<[data].data_key[km_per_fuel]>].round.format_number> km"
    - define "dest_lore:->:<gray>Fuel needed now<&co> <white><[need].div[<[eff]>].round_up> <[fuel_name]>"
    - define "dest_lore:->:<gray>Same trip<&co> <white><[need].round_up> <gray>fuel buckets or <white><[need].div[6].round_up> <gray>methane"
    - define dest_lore:->:<&sp>
    - define dest_lore:->:<[status]>

# Fills a planner inventory. Expects <[inventory]>. Inject only.
launch_planner_fill:
  type: task
  debug: false
  script:
  - define data <script[launch_planner_data]>
  - define fuel <player.flag[launch_planner.fuel].if_null[fuel_bucket]>
  - if !<[data].data_key[fuels].contains[<[fuel]>]>:
    - define fuel fuel_bucket
  - define amount <player.flag[launch_planner.amount].if_null[100]>
  - define fuel_info <[data].data_key[fuels.<[fuel]>].split[/]>
  - define eff <[fuel_info].get[1]>
  - define fuel_name <[fuel_info].get[3]>
  - define range <[amount].mul[<[eff]>]>
  - define now <util.current_time_millis>
  # ---- space background
  - define space <item[black_stained_glass_pane].with_single[display=<&sp>]>
  - repeat 45 as:cell:
    - inventory set d:<[inventory]> slot:<[cell]> o:<[space]>
  - foreach <[data].data_key[stars]> as:star:
    - inventory set d:<[inventory]> slot:<[star]> o:<item[white_stained_glass_pane].with_single[display=<dark_gray>✦]>
  # ---- the Sun
  - define sun_lore <list>
  - define "sun_lore:->:<gray>Planets sit where they really are in"
  - define "sun_lore:->:<gray>Galactifun right now, moving in real time."
  - define sun_lore:->:<&sp>
  - define "sun_lore:->:<green>Green <gray>= in range with your fuel now"
  - define "sun_lore:->:<yellow>Yellow <gray>= comes into range soon"
  - define "sun_lore:->:<red>Red <gray>= needs more or better fuel"
  - define sun_lore:->:<&sp>
  - define "sun_lore:->:<gray>Hover a planet or moon for details."
  - define "sun_lore:->:<gray>Set your fuel along the bottom row."
  - define sun_lore:->:<&sp>
  - define "sun_lore:->:<dark_gray>Your rocket only lists places its"
  - define "sun_lore:->:<dark_gray>loaded fuel can reach."
  - inventory set d:<[inventory]> slot:23 o:<item[shroomlight].with_single[display=<gold><bold>☀ The Sun].with_single[lore=<[sun_lore]>]>
  - define used <list[23]>
  # ---- planets at their real orbital angles
  - define moon_queue <list>
  - foreach <[data].data_key[map_planets]> as:entry:
    - define p <[entry].split[/]>
    - define year <[data].data_key[bodies.<[p].get[1]>].split[/].get[2]>
    - define theta <[now].mod[<[year]>].mul[<util.pi>].mul[2].div[<[year]>]>
    - define x <[theta].cos.mul[<[p].get[2]>].round.add[4]>
    - define y <element[2].sub[<[theta].sin.mul[<[p].get[3]>].round>]>
    - inject launch_planner_place
    - if <[slot]> == null:
      - foreach next
    - define name <[p].get[5]>
    - define moons <[p].get[6].if_null[<empty>]>
    - define lore <list>
    - if <[name]> == Earth:
      - define title "<aqua><bold>Earth <gray>(launch from here)"
      - define "lore:->:<gray>Your home planet and launch site."
    - else if <[moons].length> == 0:
      # The planet itself is a destination (Venus, Mars).
      - define find <[name]>
      - inject launch_planner_find
      - inject launch_planner_dest
      - define title <[color]><bold><[name]>
      - define lore <[dest_lore]>
    - else:
      - define title <gold><bold><[name]>
      - define "lore:->:<gray>Gas giant, so you land on its moons."
    - if <[moons].length> > 0:
      - define lore:->:<&sp>
      - define "lore:->:<gray>Moons you can land on<&co>"
      - foreach <[moons].split[,]> as:moon:
        - define find <[moon]>
        - inject launch_planner_find
        - inject launch_planner_dest
        - define "lore:->:<[color]>● <white><[moon]><gray><&co> <white><[need].div[<[eff]>].round_up> <[fuel_name]>"
        - define moon_queue:->:<[moon]>/<[slot]>
    - inventory set d:<[inventory]> slot:<[slot]> o:<item[<[p].get[4]>].with_single[display=<[title]>].with_single[lore=<[lore]>].with_single[hides=ALL]>
  # ---- moons next to their planets
  - foreach <[moon_queue]> as:queued:
    - define moon <[queued].before_last[/]>
    - define parent_slot <[queued].after_last[/]>
    - define x <[parent_slot].sub[1].mod[9]>
    - define y <[parent_slot].sub[1].div[9].round_down>
    - inject launch_planner_place
    - if <[slot]> == null:
      - foreach next
    - define find <[moon]>
    - inject launch_planner_find
    - inject launch_planner_dest
    - define lore <[dest_lore].include[<&sp>|<dark_gray>A moon, shown beside its planet.]>
    - inventory set d:<[inventory]> slot:<[slot]> o:<item[<[target].split[/].get[4]>].with_single[display=<[color]><[moon]>].with_single[lore=<[lore]>].with_single[hides=ALL]>
  # ---- control bar
  - inventory set d:<[inventory]> slot:46 o:<item[gray_stained_glass_pane].with_single[display=<&sp>]>
  - define fuel_lore <list>
  - foreach <[data].data_key[fuel_order]> as:id:
    - define f <[data].data_key[fuels.<[id]>].split[/]>
    - if <[id]> == <[fuel]>:
      - define "fuel_lore:->:<green>▶ <[f].get[3]> <gray>(<[f].get[1]>x)"
    - else:
      - define "fuel_lore:->:<dark_gray>  <[f].get[3]> (<[f].get[1]>x)"
  - define fuel_lore:->:<&sp>
  - define "fuel_lore:->:<yellow>Click to change fuel"
  - inventory set d:<[inventory]> slot:47 o:<item[<[fuel_info].get[2]>].with_single[display=<gold>Fuel<&co> <white><[fuel_name]>].with_single[lore=<[fuel_lore]>].with_single[hides=ALL].with_flag[launch_planner_action:cycle]>
  - inventory set d:<[inventory]> slot:48 o:<item[minecart].with_single[display=<white>Tier 1 rocket].with_single[lore=<list[<gray>Holds 10 fuel|<yellow>Click to set 10]>].with_flag[launch_planner_action:amount:10]>
  - inventory set d:<[inventory]> slot:49 o:<item[chest_minecart].with_single[display=<white>Tier 2 rocket].with_single[lore=<list[<gray>Holds 100 fuel|<yellow>Click to set 100]>].with_flag[launch_planner_action:amount:100]>
  - inventory set d:<[inventory]> slot:50 o:<item[furnace_minecart].with_single[display=<white>Tier 3 or ion rocket].with_single[lore=<list[<gray>Holds 500 fuel|<yellow>Click to set 500]>].with_flag[launch_planner_action:amount:500]>
  - define tank_lore <list>
  - define "tank_lore:->:<gray>Fuel<&co> <white><[fuel_name]>"
  - define "tank_lore:->:<gray>Reach<&co> <white><[range].round_down> <gray>(in fuel buckets)"
  - define tank_lore:->:<&sp>
  - define "tank_lore:->:<yellow>Left click +1, right click -1"
  - define "tank_lore:->:<yellow>Shift click for 10"
  - inventory set d:<[inventory]> slot:51 o:<item[hopper].with_single[display=<gold>In the tank<&co> <white><[amount]>].with_single[lore=<[tank_lore]>].with_flag[launch_planner_action:tank]>
  - inventory set d:<[inventory]> slot:52 o:<item[gray_stained_glass_pane].with_single[display=<&sp>]>
  - inventory set d:<[inventory]> slot:53 o:<item[clock].with_single[display=<aqua>Refresh].with_single[lore=<list[<gray>Updated <util.time_now.to_utc.format[HH:mm]> GMT|<yellow>Click to update the map]>].with_flag[launch_planner_action:refresh]>
  - inventory set d:<[inventory]> slot:54 o:<item[barrier].with_single[display=<red>Close].with_flag[launch_planner_action:close]>

launch_planner_events:
  type: world
  debug: false
  events:
    on player clicks item_flagged:launch_planner_action in launch_planner_gui:
    - ratelimit <player> 5t
    - define action <context.item.flag[launch_planner_action]>
    - define data <script[launch_planner_data]>
    - define max <[data].data_key[max_amount]>
    - define current <player.flag[launch_planner.amount].if_null[100]>
    - choose <[action].split[:].first>:
      - case cycle:
        - define order <[data].data_key[fuel_order]>
        - define index <[order].find[<player.flag[launch_planner.fuel].if_null[fuel_bucket]>]>
        - flag <player> launch_planner.fuel:<[order].get[<[index].max[0].mod[<[order].size>].add[1]>]>
      - case amount:
        - flag <player> launch_planner.amount:<[action].split[:].get[2]>
      - case tank:
        - define step <context.click.starts_with[SHIFT].if_true[10].if_false[1]>
        - if <context.click.contains_text[RIGHT]>:
          - define step <[step].mul[-1]>
        - flag <player> launch_planner.amount:<[current].add[<[step]>].max[1].min[<[max]>]>
      - case close:
        - inventory close
        - stop
    - define inventory <context.inventory>
    - inject launch_planner_fill

# ---------------------------------------------------------------- command

launch_planner_command:
  type: command
  debug: false
  name: launchplanner
  description: Shows which Galactifun planets your rocket can reach and when.
  usage: /planets [fuel] [amount]
  aliases:
  - planets
  - launchwindows
  tab completions:
    1: fuel_bucket|oil|hydrogen|ammonia|methane|argon
    2: 100|500
  script:
  - ratelimit <player> 3s
  - if <context.args.is_empty>:
    - define inventory <inventory[launch_planner_gui]>
    - inject launch_planner_fill
    - inventory open d:<[inventory]>
    - stop
  # chat version: /planets <fuel> [amount]
  - define fuel <context.args.get[1].to_lowercase>
  - define amount <context.args.get[2].if_null[100]>
  - define fuel_info <script[launch_planner_data].data_key[fuels.<[fuel]>].if_null[null]>
  - if <[fuel_info]> == null || !<[amount].is_decimal>:
    - narrate "<red>Usage<&co> /planets <gray>(opens the map)"
    - narrate "<red>   or<&co> /planets <&lt>fuel_bucket|oil|hydrogen|ammonia|methane|argon<&gt> [amount loaded]"
    - stop
  - if <[amount]> <= 0:
    - narrate "<red>The amount of fuel must be more than 0."
    - stop
  - define eff <[fuel_info].split[/].get[1]>
  - define fuel_name <[fuel_info].split[/].get[3]>
  - define range <[amount].mul[<[eff]>]>
  - define now <util.current_time_millis>
  - narrate "<aqua><bold>Launch planner <reset><gray>from Earth with <white><[amount]> <[fuel_name]><gray> (reach <white><[range].round_down><gray> fuel)"
  - foreach <script[launch_planner_data].data_key[targets]> as:target:
    - define info <proc[launch_planner_status].context[<[target]>|<[range]>|<[now]>]>
    - define items <[info].get[need].div[<[eff]>].round_up>
    - narrate "<white><[target].split[/].first><gray><&co> needs <white><[items]><gray> now. <proc[launch_planner_status_text].context[<[info].get[state]>|<[info].get[minutes]>|<[info].get[best]>|<[eff]>]>"
  - narrate "<dark_gray>Tip<&co> /planets on its own opens the solar system map."
