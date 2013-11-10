Q = Game.Q

# animations object
Q.animations "player",
  stand:
    frames: [4]
    rate: 1/2
  run:
    frames: [4, 5, 6]
    rate: 1/4
  hit:
    frames: [0]
    loop: false
    rate: 1/2
    next: "stand"
  jump:
    frames: [2]
    rate: 1/2

# player object and logic
Q.Sprite.extend "Player",
  init: (p) ->
    @_super p,
      lifePoints: 3
      timeInvincible: 0
      timeToNextSave: 0
      x: 0
      y: 0
      z: 100
      savedPosition: {}
      hasKey: false
      # asset: Game.assets.player.sheet # find nice hero asset, static for the beginning
      sheet: "player"
      sprite: "player"
      type: Game.SPRITE_PLAYER
      collisionMask: Game.SPRITE_TILES | Game.SPRITE_ENEMY | Game.SPRITE_PLAYER_COLLECTIBLE

    @add("2d, platformerControls, animation, gun")

    @p.jumpSpeed = -570
    @p.speed = 300
    @p.savedPosition.x = @p.x
    @p.savedPosition.y = @p.y

    # events
    @on "bump.left, bump.right, bump.bottom, bump.top", @, "collision"
    @on "player.outOfMap", @, "restore"

  step: (dt) ->
    if @p.direction == "left"
      @p.flip = false
    if @p.direction == "right"
      @p.flip = "x"

    # check if out of map
    if @p.y > Game.map.p.h
      @p.y = 0
      # @updateLifePoints()
      # @trigger "player.outOfMap"

    if @p.x > Game.map.p.w
      @p.x = 0

    if @p.x < 0
      @p.x = Game.map.p.w

    # save
    if @p.timeToNextSave > 0
      @p.timeToNextSave = Math.max(@p.timeToNextSave - dt, 0)

    if @p.timeToNextSave == 0
      @savePosition()
      @p.timeToNextSave = 2

    # collision with enemy timeout
    if @p.timeInvincible > 0
      @p.timeInvincible = Math.max(@p.timeInvincible - dt, 0)

    # jump from too high place
    # if @p.vy > 1100
    #   @p.willBeDead = true

    # if @p.willBeDead && @p.vy < 1100
    #   @updateLifePoints()
    #   @p.willBeDead = false
    #   @trigger "player.outOfMap"

    # animations
    if @p.vy != 0
      @play("jump")
    else if @p.vx != 0
      @play("run")
    else
      @play("stand")

  collision: (col) ->
    if col.obj.isA("Enemy") && @p.timeInvincible == 0
      @updateLifePoints()

      # will be invincible for 1 second
      @p.timeInvincible = 1

  savePosition: ->
    dirX = @p.vx/Math.abs(@p.vx)
    ground = Q.stage().locate(@p.x, @p.y + @p.h/2 + 1, Game.SPRITE_TILES)

    if ground
      @p.savedPosition.x = @p.x
      @p.savedPosition.y = @p.y

  updateLifePoints: (newLives) ->
    if newLives?
      @p.lifePoints += newLives

    else
      @p.lifePoints -= 1
      Game.infoLabel.lifeLost()
      @play("hit", 1)

      if @p.lifePoints <= 0
        @destroy()
        Q.stageScene "end", 2,
          label: "You Died"

      if @p.lifePoints == 1
        Game.infoLabel.lifeLevelLow()

    # always update label
    lifesLabel = Q("UI.Text", 1).first()
    lifesLabel.p.label = "Lives: " + @p.lifePoints

  restore: ->
    @p.x = @p.savedPosition.x
    @p.y = @p.savedPosition.y
