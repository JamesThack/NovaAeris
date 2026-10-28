void_return:
  type: world
  debug: false
  events:
    on player walks:
    - if <player.world.name> != spawn:
      - stop
    - if <player.location.y> < 0:
      - teleport <player> <world[spawn].spawn_location>
