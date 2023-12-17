require('DataObj')
require('lib')
DataSet={}
local indexFileName='INDEX.json'

DataSet.READ_PERMISSION=1
DataSet.APPEND_PERMISSION=2
DataSet.WRITE_PERMISSION=3
DataSet.DELETE_PERMISSION=4
DataSet.MASTER=os.getComputerID()

function DataSet:new(obj)
	obj = obj or {}
	setmetatable(obj,self)
	self.__index=self

	---ERROR
	self.NO_SUCH_KEY='no_such_key'
	self.NO_PERMISSION='no_permission'
	return obj
end

function DataSet:init(set_path)
	local indexFile=nil
	self.index={}
	self.workDir=nil
	self.objList={}

	---check is index path
	if not set_path:find(indexFileName) then
		self.workDir=set_path
	else
		self.workDir=set_path:sub(1,#set_path-#indexFileName)
	end
	if not fs.exists(self.workDir) then
		fs.makeDir(self.workDir)
	end
	

	---add '/' to the end
	if string.sub(self.workDir,-1)~='/' then
		self.workDir=self.workDir..'/'
	end
	
	---create index file 
	if not fs.exists(self.workDir..indexFileName) then
		indexFile=io.open(self.workDir..indexFileName,'w')
		indexFile:write(textutils.serializeJSON({}))
		indexFile:close()
	end
	indexFile=fs.open(self.workDir..indexFileName,'r')

	---create dump directory
	if not fs.exists(self.workDir..'dump') then
		fs.makeDir(self.workDir..'dump')
	end
	
	---read index file
	self.index=textutils.unserializeJSON(indexFile.readAll())
	indexFile.close()

	---add file info
	for key,info in pairs(self.index) do
		self:addKey(key,info.permission,self.suffix)
	end
end

function DataSet:getKeyObj(key)
	return self.objList[key]
end

function DataSet:isAllowed(key,id,level)
	if not self:getKeyObj(key) then
		return nil,self.NO_SUCH_KEY
	elseif id==self.MASTER then
		return true
	elseif not self:getKeyObj(key):getPermission(id) then
		return false
	end
	return level<=self:getKeyObj(key):getPermission(id)
end

function DataSet:dump(key,info)
	if key then
		self.index[key]=info
	end
	local indexFile=io.open(self.workDir..indexFileName,'w')
	indexFile:write(textutils.serializeJSON(self.index))
	indexFile:close()
end

function DataSet:addKey(key,permission,suffix)
	local obj=DataObj:new()
	obj:init(key,permission,self.workDir,suffix)
	self.objList[key]=obj
	self:dump(key,obj:getInfo())
end

function DataSet:remove(key,id,dump)
	if not self:isAllowed(key,id,self.DELETE_PERMISSION) then
		return false,self.NO_PERMISSION
	end
	local obj=self:getKeyObj(key)
	obj:delete(id,dump)
	self.index[key]=nil
	self.objList[key]=nil
	self:dump()
	return true
end

function DataSet:readKey(key,id)
	if not self:isAllowed(key,id,self.READ_PERMISSION) then
		return nil,self.NO_PERMISSION
	end

	if not self:getKeyObj(key) then
		return nil,self.NO_SUCH_KEY
	end
	return (self:getKeyObj(key):read())
end

function DataSet:writeKey(key,data,id,dump)
	if not self:isAllowed(key,id,self.WRITE_PERMISSION) then
		return false,self.NO_PERMISSION
	end

	local dump=dump or false
	if not self:getKeyObj(key) then
		return false,self.NO_SUCH_KEY
	end
	self:getKeyObj(key):write(data,dump)
	self:dump(self:getKeyObj(key):getInfo())
	return true
end

function DataSet:append(key,data,id,dump)
	if not self:isAllowed(key,id,self.APPEND_PERMISSION) then
		return false,self.NO_PERMISSION
	end

	local obj=self:getKeyObj(key)
	obj:append(data,dump)
	self:dump(self:getKeyObj(key):getInfo())
end

function DataSet:addPermission(key,id,level)
	self:getKeyObj(key):setPermission(id,level)
	self:dump(self:getKeyObj(key):getInfo())
end

function DataSet:exists(key)
	if self.index[key] then
		return false
	else
		return true
	end
end

function DataSet:list()
	local list={}
	for key,obj in pairs(self.index) do
		table.insert(list,key)
	end
	return list
end

return DataSet
